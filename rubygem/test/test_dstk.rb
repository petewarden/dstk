require 'rubygems' if RUBY_VERSION < '1.9'

require 'test/unit'
require 'dstk'

class DSTKTest < Test::Unit::TestCase
  def setup
    @dstk = DSTK::DSTK.new()
  end

  def test_ip2coordinates
    input = '71.198.248.36'
    expected = {"71.198.248.36"=>{"area_code"=>510, "postal_code"=>"", "country_code3"=>"USA", "locality"=>"Berkeley", "region"=>"CA", "latitude"=>37.878101348877, "country_name"=>"United States", "dma_code"=>807, "country_code"=>"US", "longitude"=>-122.271003723145}}
    response = @dstk.ip2coordinates(input)
    assert_equal expected, response
  end

  def test_street2coordinates
    input = '2543 Graystone Pl, Simi Valley, CA 93065'
    expected = {"2543 Graystone Pl, Simi Valley, CA 93065"=>{"street_address"=>"2543 Graystone Pl","street_number"=>"2543","street_name"=>"Graystone Pl","latitude"=>34.280874,"country_code3"=>"USA","confidence"=>1.0,"longitude"=>-118.766282,"fips_county"=>"06111","country_name"=>"United States","locality"=>"Simi Valley","region"=>"CA","country_code"=>"US"}}
    response = @dstk.street2coordinates(input)
    assert_equal expected, response
  end
    
  def test_coordinates2politics
    input = [34.281016, -118.766282]
    expected = [{"politics"=>[{"code"=>"usa", "type"=>"admin2", "friendly_type"=>"country", "name"=>"United States"}, {"code"=>"06_111", "type"=>"admin6", "friendly_type"=>"county", "name"=>"Ventura"}, {"code"=>"06_72016", "type"=>"admin5", "friendly_type"=>"city", "name"=>"Simi Valley"}, {"code"=>"us06", "type"=>"admin4", "friendly_type"=>"state", "name"=>"California"}, {"code"=>"06_24", "type"=>"constituency", "friendly_type"=>"constituency", "name"=>"Twenty fourth district, CA"}], "location"=>{"longitude"=>-118.766282, "latitude"=>34.281016}}]
    response = @dstk.coordinates2politics(input)
    assert_equal expected, response
  end

  def test_text2places
    input = 'Cairo, Egypt'
    expected = [{"matched_string"=>"Cairo, Egypt", "code"=>"", "start_index"=>"0", "latitude"=>"30.05", "type"=>"CITY", "name"=>"Cairo", "longitude"=>"31.25", "end_index"=>"4"}]
    response = @dstk.text2places(input)
    assert_equal expected, response
  end

  def test_text2sentences
    input = 'kfFJF -d a  a. This should look like a real sentence. So should this, hopefully, if things are working correctly. Blahalala. Not. A  Rea;l <<<< sentence'
    expected = {"sentences"=>"kfFJF -d a  a. This should look like a real sentence. So should this, hopefully, if things are working correctly. Blahalala. Not. A  Rea;l <<<< sentence \n"}
    response = @dstk.text2sentences(input)
    assert_equal expected, response
  end

  def test_html2text
    input = '<html><head><title>Foo</title><script type="text/javascript">shouldBeIgnored();</script></head><body><p>Some text that should show up</p></body></html>'
    expected = {"text"=>"Some text that should show up\n"}
    response = @dstk.html2text(input)
    assert_equal expected, response
  end

  def test_html2story
    input = '<html><head><title>Foo</title><script type="text/javascript">shouldBeIgnored();</script></head><body><p>Some text that shouldn\'t show up</p></body></html>'
    expected = {'story' => "\n"}
    response = @dstk.html2story(input)
    assert_equal expected, response
  end

  def test_text2people
    input = 'Samuel L Jackson'
    expected = [{"first_name"=>"Samuel", "end_index"=>16, "matched_string"=>"Samuel L Jackson", "surnames"=>"L Jackson", "title"=>"", "ethnicity"=>{"percentage_black"=>53.02, "percentage_asian_or_pacific_islander"=>0.31, "percentage_hispanic"=>1.53, "percentage_two_or_more"=>2.18, "percentage_of_total"=>0.24693, "percentage_american_indian_or_alaska_native"=>1.04, "percentage_white"=>41.93, "rank"=>18}, "start_index"=>0, "gender"=>"m"}]
    response = @dstk.text2people(input)
    assert_equal expected, response
  end

  def test_text2times
    input = "March 10th at 3pm \n Something that is not a time\n"
    expected = [{"matched_string"=>"March 10th at 3pm","time_seconds"=>1394463600.0,"is_relative"=>true,"duration"=>1,"start_index"=>0,"time_string"=>"Mon Mar 10 15:00:00 +0000 2014","end_index"=>16}]
    response = @dstk.text2times(input)
    assert_equal expected, response
  end

  def test_text2sentiment
    input = 'I love this hotel!'
    expected = {'score' => 3.0}
    response = @dstk.text2sentiment(input)
    assert_equal expected, response
  end

  def test_coordinates2statistics
    input = [34.281016, -118.766282]
    expected = [{"statistics"=>{"population_density"=>{"value"=>1742, "description"=>"The number of inhabitants per square kilometer around this point.", "source_name"=>"NASA Socioeconomic Data and Applications Center (SEDAC) \342\200\223 Hosted by CIESIN at Columbia University"}}, "location"=>{"latitude"=>34.281016, "longitude"=>-118.766282}}]
    response = @dstk.coordinates2statistics(input, 'population_density')
    assert_equal expected, response
  end
end
