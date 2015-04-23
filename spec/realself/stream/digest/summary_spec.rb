describe RealSelf::Stream::Digest::Summary do

  it_should_behave_like "a summary", RealSelf::Stream::Digest::Summary::Blog
  it_should_behave_like "a summary", RealSelf::Stream::Digest::Summary::Discussion
  it_should_behave_like "a summary", RealSelf::Stream::Digest::Summary::Dr
  it_should_behave_like "a summary", RealSelf::Stream::Digest::Summary::Guide
  it_should_behave_like "a summary", RealSelf::Stream::Digest::Summary::Question
  it_should_behave_like "a summary", RealSelf::Stream::Digest::Summary::Review
  it_should_behave_like "a summary", RealSelf::Stream::Digest::Summary::Topic
  it_should_behave_like "a summary", RealSelf::Stream::Digest::Summary::User
  it_should_behave_like "a summary", RealSelf::Stream::Digest::Summary::Video

end
