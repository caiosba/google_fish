require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe GoogleFish do
  context "#new" do
    let(:query) { GoogleFish.new('key')  }

    it "should create a new instance with an api key" do
      query.key.should eq 'key'
    end
  end

  context "#translate" do
    context "text" do
      let(:query) { GoogleFish.new('123') }
      let(:mock_request) { mock(GoogleFish::Request) }
      before do
        GoogleFish::Request.should_receive(:new).with(query).
          and_return(mock_request)
        mock_request.should_receive(:perform_translation).and_return 'hola'
        query.translate(:en, :es, 'hi')
      end

      it "should store the params" do
        query.source.should eq :en
        query.target.should eq :es
        query.q.should eq 'hi'
        query.format.should eq :text
      end

      it "should store the translation" do
        query.translated_text.should eq 'hola'
      end
    end

    context "html" do
      let(:query) { GoogleFish.new('123') }
      let(:mock_request) { mock(GoogleFish::Request) }
      before do
        GoogleFish::Request.should_receive(:new).with(query).
          and_return(mock_request)
        mock_request.should_receive(:perform_translation).and_return 'hola'
        query.translate(:en, :es, 'hi', :html => true)
      end

      it "should store the params" do
        query.source.should eq :en
        query.target.should eq :es
        query.q.should eq 'hi'
        query.format.should eq :html
      end

      it "should store the translation" do
        query.translated_text.should eq 'hola'
      end
    end
  end

  context "#languages" do
    context "target" do
      let(:query) { GoogleFish.new('123') }
      let(:mock_request) { mock(GoogleFish::Request) }
      before do
        GoogleFish::Request.should_receive(:new).with(query).
          and_return(mock_request)
        mock_request.should_receive(:get_supported_languages).and_return ['es']
        query.get_supported_languages(:en)
      end

      it "should store the params" do
        query.target.should eq :en
      end

      it "should store the list of languages" do
        query.supported_languages.should eq ['es']
      end
    end

    context "no target" do
      let(:query) { GoogleFish.new('123') }
      let(:mock_request) { mock(GoogleFish::Request) }
      before do
        GoogleFish::Request.should_receive(:new).with(query).
          and_return(mock_request)
        mock_request.should_receive(:get_supported_languages).and_return ['pt']
        query.get_supported_languages
      end

      it "should store the params" do
        query.target.should eq nil
      end

      it "should store the list of languages" do
        query.supported_languages.should eq ['pt']
      end
    end
  end

end

describe GoogleFish::Request do
  context "#new" do
    let(:query) { GoogleFish.new('key') }
    let(:request) { GoogleFish::Request.new(query) }

    it "should store the query" do
      request.query.should eq query
    end
  end

  context "#perform_translation" do
    context "good response" do 
      let(:query) { GoogleFish.new('key') }
      let(:request) { GoogleFish::Request.new(query) }
      let(:stubbed_response) { File.open('spec/support/good.json') }

      before do
        query.format, query.source, query.target, query.q = :text, :en, :es, 'hello'
        stub_request(:get, "https://www.googleapis.com/language/translate/v2?format=text&key=key&q=hello&source=en&target=es").
          to_return(stubbed_response)
        request.perform_translation
      end

      it "should store the response" do
        request.response.should eq "{\n \"data\": {\n  \"translations\": [\n   {\n    \"translatedText\": \"hola\"\n   }\n  ]\n }\n}\n"
      end

      it "should store the parsed response" do
        request.parsed_response.should eq 'hola'
      end
    end

    context "bad response" do
      let(:query) { GoogleFish.new('key') }
      let(:request) { GoogleFish::Request.new(query) }
      let(:stubbed_response) { File.open('spec/support/bad.json') }

      before do
        query.format, query.source, query.target, query.q = :text, :en, :es, 'hello'
        stub_request(:get, "https://www.googleapis.com/language/translate/v2?format=text&key=key&q=hello&source=en&target=es").
          to_return(stubbed_response)
      end

      it "should raise an error if response is bad" do
        expect { request.perform_translation }.to raise_error GoogleFish::Request::ApiError
      end
    end

    context "good html response" do 
      let(:query) { GoogleFish.new('key') }
      let(:request) { GoogleFish::Request.new(query) }
      let(:stubbed_response) { File.open('spec/support/good_html.json') }

      before do
        query.source, query.target, query.q, query.format = :en, :es, 'hello', 'html'
        stub_request(:get, "https://www.googleapis.com/language/translate/v2?format=html&key=key&q=hello&source=en&target=es").
          to_return(stubbed_response)
        request.perform_translation
      end

      it "should store the response" do
        request.response.should eq "{\n \"data\": {\n  \"translations\": [\n   {\n    \"translatedText\": \"\\u003cp\\u003e hola \\u003c/p\\u003e\"\n   }\n  ]\n }\n}\n"
      end

      it "should store the parsed response" do
        request.parsed_response.should eq '<p> hola </p>'
      end
    end
  end

  context "#get_supported_languages" do
    context "no target" do 
      let(:query) { GoogleFish.new('key') }
      let(:request) { GoogleFish::Request.new(query) }
      let(:stubbed_response) { File.open('spec/support/languages2.json') }

      before do
        stub_request(:get, "https://www.googleapis.com/language/translate/v2/languages?key=key").
          to_return(stubbed_response)
        request.get_supported_languages
      end

      it "should store the response" do
        request.response.should eq "{\n \"data\": {\n  \"languages\": [\n   {\n    \"language\": \"pt\"\n   }\n  ]\n }\n}\n"
      end

      it "should store the parsed response" do
        request.parsed_response.should eq ['pt']
      end
    end

    context "bad response" do
      let(:query) { GoogleFish.new('key') }
      let(:request) { GoogleFish::Request.new(query) }
      let(:stubbed_response) { File.open('spec/support/bad.json') }

      before do
        stub_request(:get, "https://www.googleapis.com/language/translate/v2/languages?key=key").
          to_return(stubbed_response)
      end

      it "should raise an error if response is bad" do
        expect { request.get_supported_languages }.to raise_error GoogleFish::Request::ApiError
      end
    end

    context "has target" do 
      let(:query) { GoogleFish.new('key') }
      let(:request) { GoogleFish::Request.new(query) }
      let(:stubbed_response) { File.open('spec/support/languages.json') }

      before do
        query.target = :en
        stub_request(:get, "https://www.googleapis.com/language/translate/v2/languages?key=key&target=en").
          to_return(stubbed_response)
        request.get_supported_languages
      end

      it "should store the response" do
        request.response.should eq "{\n \"data\": {\n  \"languages\": [\n   {\n    \"language\": \"es\"\n   }\n  ]\n }\n}\n"
      end

      it "should store the parsed response" do
        request.parsed_response.should eq ['es']
      end
    end
  end
 
  
end

describe "Integration test" do
  context "readme example" do
    let(:text_response) { File.open('spec/support/good.json') }
    let(:html_response) { File.open('spec/support/good_html.json') }
    let(:languages) { File.open('spec/support/languages2.json') }
    before do
      stub_request(:get, "https://www.googleapis.com/language/translate/v2?format=text&key=key&q=hi&source=en&target=es").
       with(:headers => {'Accept'=>'*/*'}).
          to_return(text_response)
      stub_request(:get, "https://www.googleapis.com/language/translate/v2?format=html&key=key&q=hi&source=en&target=es").
       with(:headers => {'Accept'=>'*/*'}).
          to_return(html_response)
      stub_request(:get, "https://www.googleapis.com/language/translate/v2/languages?key=key").
       with(:headers => {'Accept'=>'*/*'}).
          to_return(languages)
    end
    it "should work" do
      google = GoogleFish.new('key')
      google.translate(:en, :es, 'hi').should eq 'hola'
      google.translate(:en, :es, 'hi', :html => true).should eq '<p> hola </p>'
      google.get_supported_languages.should eq ['pt']
    end
  end
end
