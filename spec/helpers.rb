module Helpers

  @@activity_version = 2

  def self.init(activity_version)
    @@activity_version = activity_version.to_i
  end

  def objekts_array
    array = []
    array.push(RealSelf::Stream::Objekt.new('user', 1234))
    array.push(RealSelf::Stream::Objekt.new('user', 2345))
    array
  end

  def example_hash

    hash = {
      :title => "sample activity title",
      :published => "1970-01-01T00:00:00+00:00",
      :actor => {:type => "dr", :id => "1234"},
      :verb => "author",
      :object => {:type => "answer", :id => "2345"},
      :uuid => "f364c40c-6e91-4064-a825-faae79c10254",
      :target => {:type => "question", :id => "3456"},
      :prototype => "explicit.prototype.value"
    }

    case @@activity_version
    when 1
      hash[:relatives] = [{:type => "topic", :id => "4567"}]
    when 2
      hash[:version] = 2
      hash[:extensions] = {:topic => {:type => "topic", :id => "4567"}}
    else
      hash[:version] = @@activity_version
    end

    return hash
  end

  def example_activity
    case @@activity_version
    when 1
      RealSelf::Stream::Activity.create(@@activity_version,
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('dr', 1234),
        'author',
        RealSelf::Stream::Objekt.new('answer', 2345),
        RealSelf::Stream::Objekt.new('question', 3456),
        [RealSelf::Stream::Objekt.new('topic', 4567)],
        "f364c40c-6e91-4064-a825-faae79c10254",
        "explicit.prototype.value"
      )
    when 2
      RealSelf::Stream::Activity.create(@@activity_version,
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('dr', 1234),
        'author',
        RealSelf::Stream::Objekt.new('answer', 2345),
        RealSelf::Stream::Objekt.new('question', 3456),
        {:topic => RealSelf::Stream::Objekt.new('topic', 4567)},
        "f364c40c-6e91-4064-a825-faae79c10254",
        "explicit.prototype.value"
      )
    end
  end

  def example_activity_without_uuid
    case @@activity_version
    when 1
      RealSelf::Stream::Activity.create(@@activity_version,
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('dr', 1234),
        'author',
        RealSelf::Stream::Objekt.new('answer', 2345),
        RealSelf::Stream::Objekt.new('question', 3456),
        [RealSelf::Stream::Objekt.new('topic', 4567)]
      )
    when 2
      RealSelf::Stream::Activity.create(@@activity_version,
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('dr', 1234),
        'author',
        RealSelf::Stream::Objekt.new('answer', 2345),
        RealSelf::Stream::Objekt.new('question', 3456),
        {:topic => RealSelf::Stream::Objekt.new('topic', 4567)}
      )
    end
  end

  def example_activity_without_prototype
    case @@activity_version
    when 1
      RealSelf::Stream::Activity.create(@@activity_version,
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('dr', 1234),
        'author',
        RealSelf::Stream::Objekt.new('answer', 2345),
        RealSelf::Stream::Objekt.new('question', 3456),
        [RealSelf::Stream::Objekt.new('topic', 4567)],
        "f364c40c-6e91-4064-a825-faae79c10254"
      )
    when 2
      RealSelf::Stream::Activity.create(@@activity_version,
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('dr', 1234),
        'author',
        RealSelf::Stream::Objekt.new('answer', 2345),
        RealSelf::Stream::Objekt.new('question', 3456),
        {:topic => RealSelf::Stream::Objekt.new('topic', 4567)},
        "f364c40c-6e91-4064-a825-faae79c10254"
      )
    end
  end

  def example_activity_without_target_or_relatives
    RealSelf::Stream::Activity.create(@@activity_version,
      'sample activity title',
      DateTime.parse('1970-01-01T00:00:00Z'),
      RealSelf::Stream::Objekt.new('dr', 1234),
      'author',
      RealSelf::Stream::Objekt.new('answer', 2345),
      nil,
      nil,
      "f364c40c-6e91-4064-a825-faae79c10254"
    )
  end

  def user_create_thing_activity(user_id = Random::rand(1000..9999), thing_id = Random::rand(1000..9999))
    RealSelf::Stream::Activity.create(2,
      "user(#{user_id}) create thing(#{thing_id}",
      DateTime.parse('1970-01-01T00:00:00Z'),
      RealSelf::Stream::Objekt.new('user', user_id),
      'create',
      RealSelf::Stream::Objekt.new('thing', thing_id),
      nil,
      nil,
      SecureRandom.uuid,
      'user.create.thing'
      )
  end

  def user_update_thing_activity(user_id = Random::rand(1000..9999), thing_id = Random::rand(1000..9999))
    RealSelf::Stream::Activity.create(2,
      "user(#{user_id}) update thing(#{thing_id}",
      DateTime.parse('1970-01-01T00:00:00Z'),
      RealSelf::Stream::Objekt.new('user', user_id),
      'update',
      RealSelf::Stream::Objekt.new('thing', thing_id),
      nil,
      nil,
      SecureRandom.uuid,
      'user.update.thing'
      )
  end

  def followed_activity(i)
    hash = {
      :published => "1970-01-01T00:00:00+00:00",
      :title => "QUEUE ITEM - dr(57433) author answer(1050916) about question(1048591)",
      :actor =>
      {
        :type => "dr",
        :id => i.to_s,
        :followers =>
        [
          {
            :type => "user",
            :id => "2345"
          }
        ]
      },
      :verb => "author",
      :object =>
      {
        :type => "answer",
        :id => "1050916",
        :followers =>
        [
          {
            :type => "user",
            :id => "3456"
          },
          {
            :type => "user",
            :id => "4567"
          }
        ]
      },
      :target =>
      {
        :type =>"question",
        :id =>"1048591",
        :followers =>
        [
          {
            :type => "user",
            :id => "5678"
          },
          {
            :type => "user",
            :id => "6789"
          }
        ]
      },
      :uuid => 'f364c40c-6e91-4064-a825-faae79c10254',
      :prototype => "explicit.prototype.value"
    }

    case @@activity_version
    when 1
      hash[:relatives] =
      [
        {
          :type => "topic",
          :id => "265299",
          :followers =>
          [
            {
              :type => "user",
              :id => "7890"
            },
            {
              :type => "user",
              :id => "8901"
            }
          ]
        }
      ]
    when 2
      hash[:extensions] =
      {
        :topic =>
        {
          :type => "topic",
          :id => "265299",
          :followers =>
          [
            {
              :type => "user",
              :id => "7890"
            },
            {
              :type => "user",
              :id => "8901"
            }
          ]
        }
      }

      hash[:version] = 2
    else
      hash[:version] = @@activity_version
    end

    return hash
  end

  class SampleSummary
    include RealSelf::Stream::Digest::Summarizable

    SUMMARY_TYPE = :thing

    def initialize(object)
      super
      hash = {:thing => {:count => 0}}
      @activities.merge!(hash)
    end

    def add(stream_activity)
      activity = stream_activity.activity
      case activity.prototype
      when 'user.create.thing'
        @activities[:thing][:count] += 1
        @activities[:thing][:last] = activity.object.to_h
      # sometimes we may not want to summarize a particular
      # activity type - just return without setting @empty
      when 'user.update.thing'
        return
      else
        super
      end

      @empty = false
    end

    RealSelf::Stream::Digest::Digest.register_summary_type(:thing, self)
  end

end

# require_relative 'activity_shared_examples'
# require_relative 'followed_activity_shared_examples'
