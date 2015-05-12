describe RealSelf::Handler::Enclosure do
  it "implements #handle" do
    expect(RealSelf::Handler::Enclosure.methods.include? :handle).to eql true
  end

  it "yields when #handle is called" do
    test = false

    RealSelf::Handler::Enclosure.handle do
      test = true
    end

    expect(test).to eql true
  end
end
