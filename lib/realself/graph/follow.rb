module RealSelf
  module Graph
    module Follow
      ##
      # sets the MongoDB to use
      #
      # @param [Mongo::Database] The database to use
      def self.configure mongo_db
        @mongo_db = mongo_db
      end


      ##
      # count the number of followers of a specified type of a given object
      #
      # @param [String] The type of actors doing the following e.g. :user
      # @param [Objekt] The item for which the number of followers should be counted
      #
      # @return [Integer] The number of followers
      def self.count_followers_of actor_type, object
        get_collection(actor_type).find({:'object' => object.to_h}).count
      end


      ##
      # create indexes on the collection if necessary
      #
      # @param [String] owner_type  The type of actor that is doing the following
      # @param [true | false]       Create the index in the background
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


      ##
      # test if an actor is following one or more objects.  If the
      # actor is following any of the passed objects, they will be
      # included as an element in the returned array
      #
      # @param [Objekt]             actor   The follower
      # @param [Objekt | Array]     objects An Objekt or array of Objeks to test
      # @param [&block] (optional)  a block to execute for each Objekt in the result
      #
      # @return [Array] An array containing zero or more of the passed objects
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


      ##
      # create a follow relationship
      #
      # @param [Objekt] actor The follower
      # @param [Objekt] object The item being followed
      def self.follow actor, object
        upsert_query = {:'actor.id' => actor.id, :'object' => object.to_h}

        1 == get_collection(actor.type).find(upsert_query)
          .update_one(
            {:actor => actor.to_h, :object => object.to_h},
            {:upsert => true}).n
      end


      ##
      # gets the objects that an actor is following
      #
      # @param [Objekt] The follower
      # @param [&block] (optional) A block to execute for each Objekt being followed
      #
      # @return (Array) An array of Objekts that the actor is following
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


      ##
      # gets the objects that an actor is following
      #
      # @param [String] The type of actors to include e.g. :user
      # @param [Objekt] The object being followed
      # @param [&block] (optional) A block to execute for each actor following the object
      #
      # @return (Array) An array of Objekts containing the actors
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

      ##
      # destroy a follow relationship
      #
      # @param [Objekt] actor The follower
      # @param [Objekt] object The item being followed
      #
      # @return [Bool] true if the follow relationship existed and was deleted
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
