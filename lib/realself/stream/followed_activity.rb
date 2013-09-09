require 'json-schema'
require 'realself/stream/activity'
require 'realself/stream/objekt'
require 'realself/stream/followed_objekt'
require 'realself/stream/stream_activity'

module RealSelf
  module Stream
    class FollowedActivity < Activity

      class << self   
        @@schema = MultiJson.decode(open(File.join(File.dirname(__FILE__), 'queue-item-schema.json')).read)

        def from_json(json)
          JSON::Validator.validate!(@@schema, json)
          hash = MultiJson.decode(json)

          title = hash['title']
          published = DateTime.parse(hash['published'])          
          actor = FollowedObjekt.from_json(MultiJson.encode(hash['actor'])) 
          verb = hash['verb'].to_s
          object = FollowedObjekt.from_json(MultiJson.encode(hash['object']))
          target = FollowedObjekt.from_json(MultiJson.encode(hash['target'])) if hash['target']
          relatives = hash['relatives'].map {|rel| FollowedObjekt.from_json(MultiJson.encode(rel))} if hash['relatives']

          return FollowedActivity.new(title, published, actor, verb, object, target, relatives)
        end
      end

      def to_activity
        title = self.title
        published = self.published
        actor = Objekt.new(@actor.type, @actor.id)
        verb = self.verb
        object = Objekt.new(@object.type, @object.id)
        target = Objekt.new(@target.type, @target.id) if @target
        relatives = @relatives.map { |rel| Objekt.new(rel.type, rel.id) } if @relatives

        return Activity.new(title, published, actor, verb, object, target, relatives)
      end

      # yeields follower, reason
      def map_followers

        activity = self.to_activity

        # actor
        actor_objekt = self.actor.to_objekt
        yield actor_objekt, actor_objekt

        # actor followers
        if self.actor.followers
          self.actor.followers.each do |follower|
            yield follower, actor_objekt
          end
        end

        # object
        object_objekt = self.object.to_objekt
        yield object_objekt, object_objekt

        # object followers
        if self.object.followers
          self.object.followers.each do |follower|
            yield follower, object_objekt
          end
        end

        # target
        if self.target
          target_objekt = self.target.to_objekt
          yield target_objekt, target_objekt

          # target followers
          if self.target.followers
            self.target.followers.each do |follower|
              yield follower, target_objekt
            end
          end
        end

        # relatives
        if self.relatives
          self.relatives.each do |relative|
            relative_objekt = relative.to_objekt

            yield relative_objekt, relative_objekt

            if relative.followers
              relative.followers.each do |follower|
                yield follower, relative_objekt  
              end
            end
          end
        end

      end # map_followers  

    end # FollowedActivity
  end # Stream
end # RealSelf