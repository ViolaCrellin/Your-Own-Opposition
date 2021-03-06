class UrlParser

  attr_reader :user_urls, :papers

  def initialize(user_urls= Array.new)
    @user_urls = user_urls
  end

  def papers(sources=Papers.new)
    sources.list
  end

  def news_source_list
    user_urls.map{|url| extract_sources(url)}.flatten
  end

  def topics_list
    (user_urls.map{|url| extract_keywords(url)}.flatten - news_source_list).map!{|word| word.downcase}
  end

private

  def extract_sources(url)
    extract_keywords(url).keep_if {|news_source| papers.has_key? news_source}
  end

  def extract_keywords(url)
    parse(url).delete_if { |keyword| irrelevant_keyword?(keyword)}.map!{|keyword| keyword.to_sym}
  end

  def parse(url)
    url.gsub(/\d/, '').split(/\W/)
  end

  def irrelevant_keyword?(keyword)
    ['www', 'http', 'com', 'html', 'co'].include?(keyword) || keyword.length <= 3
  end

end
