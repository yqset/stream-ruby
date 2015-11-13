module RealSelf
  module Graph
    module Follow


      def self.configure mongo_client
        @mongo_db = mongo_client
      end


      def self.count_followers_of actor_type, object
        get_collection(actor_type).find({:'object' => object.to_h}).count
      end


      def self.ensure_index(actor_type, background = true)
        get_collection(actor_type).indexes.create_many([
          {
            :key => {
              :'actor.id' => Mongo::Index::DESCENDING,
              :object     => Mongo::Index::DESCENDING
            },
            :background => background,
            :unique     => true
          },
          {
            :key => {
              :object     => Mongo::Index::DESCENDING
            },
            :background => background
          },
        ])
      end


      def self.is_following actor, objects
        objects = [*objects].map {|obj| obj.to_h}

        cursor = get_collection(actor.type).find(
          {:object => {:'$in' => objects}},
          {:fields => {:_id => 0, :actor => 0}})

        if block_given?
          cursor.each do |item|
            yield RealSelf::Stream::Objekt.from_hash(item[:object])
          end

        else
          cursor.to_a.map { |item| RealSelf::Stream::Objekt.from_hash(item[:object]) }
        end
      end


      def self.follow actor, object
        upsert_query = {:'actor.id' => actor.id, :'object' => object.to_h}

        1 == get_collection(actor.type).find(upsert_query)
          .update_one(
            {:actor => actor.to_h, :object => object.to_h},
            {:upsert => true}).n
      end


      def self.followed_by actor
        cursor = get_collection(actor.type).find(
          {:'actor.id' => actor.id}, # query
          {:fields => {:_id => 0, :actor => 0}})

        if block_given?
          cursor.each do |item|
            yield RealSelf::Stream::Objekt.from_hash(item[:object])
          end

        else
          cursor.to_a.map { |item| RealSelf::Stream::Objekt.from_hash(item[:object]) }
        end
      end


      def self.followers_of actor_type, object
        cursor = get_collection(actor_type).find(
          {:object => object.to_h},
          {:fields => {:_id => 0, :object => 0}})

        if block_given?
          cursor.each do |item|
            yield RealSelf::Stream::Objekt.from_hash(item[:actor])
          end

        else
          cursor.to_a.map { |item| RealSelf::Stream::Objekt.from_hash(item[:actor]) }
        end
      end


      def self.unfollow actor, object
        1 == get_collection(actor.type).delete_one({:'actor.id' => actor.id, :'object.id' => object.id}).n
      end


      private


      def self.get_collection actor_type
        @mongo_db.collection("graph.#{actor_type}.follow")
      end
    end
  end
end
