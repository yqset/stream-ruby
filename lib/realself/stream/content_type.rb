module RealSelf
  module Stream
    class ContentType
      ACTIVITY          = 'application/com.realself.activity+json'
      DIGEST_ACTIVITY   = 'application/com.realself.digest_activity+json'
      FOLLOWED_ACTIVITY = 'application/com.realself.followed_activity+json'
      OBJEKT            = 'application/com.realself.objekt+json'
      STREAM_ACTIVITY   = 'application/com.realself.stream_activity+json'
    end

    class ContentTypeError < StandardError
    end
  end
end