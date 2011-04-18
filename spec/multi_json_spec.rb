require 'spec_helper'

class MockDecoder
  def self.decode(string, options = {})
    { 'abc' => 'def' }
  end

  def self.encode(string)
    '{"abc":"def"}'
  end
end

describe "MultiJson" do
  context 'engines' do
    it 'should default to the best available gem' do
      # the yajl-ruby gem does not work on jruby, so the best engine is the JsonGem engine
      if jruby?
        require 'json'
        MultiJson.engine.name.should == 'MultiJson::Engines::JsonGem'
      else
        require 'yajl'
        MultiJson.engine.name.should == 'MultiJson::Engines::Yajl'
      end
    end

    it 'should be settable via a symbol' do
      MultiJson.engine = :json_gem
      MultiJson.engine.name.should == 'MultiJson::Engines::JsonGem'
    end

    it 'should be settable via a class' do
      MultiJson.engine = MockDecoder
      MultiJson.engine.name.should == 'MockDecoder'
    end
  end

  %w(json_gem json_pure okjson yajl).each do |engine|
    context engine do
      before do
        begin
          MultiJson.engine = engine
        rescue LoadError
          pending "Engine #{engine} couldn't be loaded (not installed?)"
        end
      end

      describe '.encode' do
        it 'should write decodable JSON' do
          [
            { 'abc' => 'def' },
            [1, 2, 3, "4"]
          ].each do |example|
            MultiJson.decode(MultiJson.encode(example)).should == example
          end
        end

        it 'should encode symbol keys as strings' do
          encoded_json = MultiJson.encode({ :foo => { :bar => 'baz' } })
          MultiJson.decode(encoded_json).should == { 'foo' => { 'bar' => 'baz' } }
        end
      end

      describe '.decode' do
        it 'should properly decode valid JSON' do
          MultiJson.decode('{"abc":"def"}').should == { 'abc' => 'def' }
        end

        it 'should raise MultiJson::DecodeError on invalid JSON' do
          lambda do
            MultiJson.decode('{"abc"}')
          end.should raise_error(MultiJson::DecodeError)
        end

        it 'should stringify symbol keys when encoding' do
          encoded_json = MultiJson.encode(:a => 1, :b => {:c => 2})
          MultiJson.decode(encoded_json).should == { "a" => 1, "b" => { "c" => 2 } }
        end

        it 'should allow for symbolization of keys' do
          MultiJson.decode('{"abc":{"def":"hgi"}}', :symbolize_keys => true).should == { :abc => { :def => 'hgi' } }
        end
      end
    end
  end
end
