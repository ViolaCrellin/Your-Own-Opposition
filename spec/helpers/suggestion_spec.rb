require 'rails_helper'

describe Suggestion, :type => :class do
  let(:dummy_url_analysis_klass) {double :dummy_url_analysis_klass}
  let(:dummy_url_analysis) {double :dummy_url_analysis}
  let(:dummy_urls) {['a', 'b']}
  subject(:suggestion) {described_class.new(dummy_urls, dummy_url_analysis_klass)}
  let(:dummy_papers) {{dailymail: 100,
                        telegraph: 80,
                        bbc: 5,
                        theguardian: -100,
                        mirror: -80,
                        thesun: 100,
                        huffingtonpost: -40,
                        buzzfeed: -20,
                        independent: -20,
                        thetimes: 60,
                        express: 20,
                        morningstar: -60}}
  let(:dummy_top_topics) {{ osborne: 3,
                            cameron: 10,
                            budget: 7,
                            immigrants: 20,
                            labour: 20,
                            corbyn: 15,
                            nice: 2,
                            one: 8,
                            housing: 15
                            }}
  let(:leftwing_score) {-40}
  let(:rightwing_score) {90}

  before do
    allow(dummy_url_analysis_klass).to receive(:new).and_return(dummy_url_analysis)
    allow(dummy_url_analysis).to receive(:papers).and_return(dummy_papers)
    allow(dummy_url_analysis).to receive(:political_leaning_perc).and_return(leftwing_score)
    allow(dummy_url_analysis).to receive(:top_topics).and_return(dummy_top_topics)
    allow(suggestion).to receive(:left_needed?)
  end

  describe '#initialize' do

    it 'is instantiated with an instance of url analysis' do
      expect(suggestion.url_analysis).to eq(dummy_url_analysis)
    end

    it 'is instantiated with an empty hash of suggested sources' do
      expect(suggestion.suggested_sources).to eq({})
    end

    it 'is instantiated with an array of urls' do
      expect(suggestion.urls).to eq(dummy_urls)
    end

    it 'retrieves current_bias score' do
      expect(suggestion.current_bias).to eq(leftwing_score)
    end

    context 'no urls supplied' do
      subject(:suggestion_no_urls) {described_class.new('', dummy_url_analysis_klass)}

      it 'defaults to an empty array if no urls are given to make a suggestion' do
        expect(suggestion_no_urls.urls).to be_empty
      end

    end
  end

  describe '#make_suggestion' do

    it 'calls find_suggestions with the score needed' do
      expect(suggestion).to receive(:eliminate_bias)
      suggestion.make_suggestion
    end

    it 'calls suggest topic' do
      expect(suggestion).to receive(:suggest_topic)
      suggestion.make_suggestion
    end

    describe '#suggest_topic' do

      it 'retrieves the top topics from url_analysis' do
        expect(dummy_url_analysis).to receive(:top_topics)
        suggestion.make_suggestion
      end

      it 'updates topic suggestions with any topics that are in the top 3 most read' do
        suggestion.make_suggestion
        expect(suggestion.topic_suggestions).to include(:labour, :immigrants, :corbyn, :cameron)
      end


    end


    describe '#eliminate_bias' do

      it 'calculates the score you need to balance your current bias score' do
        expect(suggestion).to receive(:find_suggestion).with(-60)
        suggestion.make_suggestion
      end

      context '#no urls to analyse/ balanced reading' do
        subject(:suggestion_no_urls) {described_class.new([], dummy_url_analysis_klass)}

        before do
          allow(dummy_url_analysis).to receive(:political_leaning_perc).and_return(0)
        end

        it 'does not try to generate a suggestion if no urls have been given' do
          expect(suggestion_no_urls).not_to receive(:find_suggestion)
          suggestion_no_urls.make_suggestion
        end

        it 'does not try to generate a suggestion if you are already balanced' do
          expect(suggestion_no_urls).not_to receive(:find_suggestion)
          suggestion_no_urls.make_suggestion
        end

        it 'returns ":balanced" when given no urls or have a score of 0' do
          expect(suggestion_no_urls.make_suggestion).to eq(:balanced)
        end
      end
    end

    describe '#find_suggestion' do
      subject(:suggestion) {described_class.new(dummy_urls, dummy_url_analysis_klass)}

      before do
        suggestion.make_suggestion
      end

      it 'fetches the papers hash' do
        expect(dummy_url_analysis).to receive(:papers)
        suggestion.find_suggestion(10)
      end

      it 'selects news sources that match the score you need to be balanced' do
        suggestion.find_suggestion(-60)
        expect(suggestion.best_suggestion).to include(:morningstar)
      end

      it 'whittles down to just one suggestion if two exact matches found' do
        suggestion.find_suggestion(-20)
        expect(suggestion.best_suggestion).to eq({independent: 1})
      end

      it 'calls #find_many_suggestions if no single match is found' do
        expect(suggestion).to receive(:find_many_suggestions).with(10, dummy_papers)
        suggestion.find_suggestion(10)
      end

    end

    describe '#find_many_suggestions' do

      context '#right wing suggestions needed' do
        subject(:suggestion_right) {described_class.new(dummy_urls, dummy_url_analysis_klass)}
        let(:shortlist) {{bbc: 5}}

        before do
          allow(dummy_url_analysis_klass).to receive(:new).and_return(dummy_url_analysis)
          allow(dummy_url_analysis).to receive(:papers).and_return(dummy_papers)
          allow(dummy_url_analysis).to receive(:political_leaning_perc).and_return(20/3 + 1)
          allow(suggestion_right).to receive(:filter_sources).with(10, dummy_papers).and_return(shortlist)
        end

        it 'calls #filter_sources with papers hash and score_needed' do
          suggestion_right.make_suggestion
          expect(suggestion_right).to receive(:filter_sources).with(10, dummy_papers)
          suggestion_right.find_suggestion(10)
        end

        it 'updates suggested_sources with the site names and number to read' do
          suggestion_right.make_suggestion
          expect(suggestion_right.suggested_sources).to eq({bbc: 2})
        end

      end
    end

    describe '#filter_sources' do

      context '#left wing needed' do
        subject(:suggestion_left) {described_class.new(dummy_urls, dummy_url_analysis_klass)}
        # let(:shortlist) {{bbc: 5}}

        before do
          allow(dummy_url_analysis_klass).to receive(:new).and_return(dummy_url_analysis)
          allow(dummy_url_analysis).to receive(:papers).and_return(dummy_papers)
          allow(dummy_url_analysis).to receive(:political_leaning_perc).and_return(20)
          suggestion_left.make_suggestion
        end


        it 'decides if you need leftwing news based on +ve score needed' do
          expect(suggestion_left).to receive(:left_needed?).with(-30).and_return(true)
          suggestion_left.find_suggestion(-30)
        end

        it 'it returns only left wing sources with scores smaller than score needed' do
          suggestion_left.find_suggestion(50)
          expect(suggestion_left.suggested_sources).to eq({:huffingtonpost=>2, :buzzfeed=>3, :independent=>3})
        end

      end

      context '#right wing needed' do

        subject(:suggestion_right) {described_class.new(dummy_urls, dummy_url_analysis_klass)}
        let(:shortlist) {{bbc: 5}}

        before do
          allow(dummy_url_analysis_klass).to receive(:new).and_return(dummy_url_analysis)
          allow(dummy_url_analysis).to receive(:papers).and_return(dummy_papers)
          allow(dummy_url_analysis).to receive(:political_leaning_perc).and_return(20/3 + 1)
          suggestion_right.make_suggestion
        end

        it 'decides you don\'t need leftwing news based on -ve score needed' do
          expect(suggestion_right).to receive(:left_needed?).and_return(false)
          suggestion_right.find_suggestion(-10)
        end

        it 'it filters sources and returns number of right wing articles you need' do
          suggestion_right.find_suggestion(-50)
          expect(suggestion_right.suggested_sources).to eq({bbc: 10, express: 3})
        end

      end
    end
  end
end
