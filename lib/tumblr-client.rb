require 'rest_client'
require 'xmlsimple'  # xml-simple gem
require 'json'

class TumblrClient
  # based on http://www.tumblr.com/docs/en/api

  API_PUBLIC_METHODS  = [ :read, :pages ]
  API_PRIVATE_METHODS = [ :dashboard, :write, :delete, :like, :unlike, :reblog, :likes, :authenticate ]
  API_JSON_METHODS    = [ :read, :dashboard ]
  
  attr_accessor :response
  
  def url_for action, json=false
    case action
    when *API_PUBLIC_METHODS
      url = "http://#{@config[:name]}.tumblr.com/api/#{action}"
    when *API_PRIVATE_METHODS
      url = "http://www.tumblr.com/api/#{action}"
    else
      raise ArgumentError, "unknown action: #{action}!"
    end
    if json
      if API_JSON_METHODS.include?(action)
        url += "/json" if json
      else
        puts "Warning: #{action} action does not accept json"
      end
    end
    url
  end
  
  def initialize config={}
    raise ArgumentError, "missing email"    unless config[:email]
    raise ArgumentError, "missing password" unless config[:password]
    @auth = { :email => config[:email], :password => config[:password] }
    self
  end

  ### Public API calls
  ###########################
  
  def read args={}
    if args.any?  
    # The most recent 20 posts are included by default. You may pass these optional GET parameters:
    # 
    #     start - The post offset to start from. The default is 0.
    #     num - The number of posts to return. The default is 20, and the maximum is 50.
    #     type - The type of posts to return. If unspecified or empty, all types of posts are returned. Must be one of text, quote, photo, link, chat, video, or audio.
    #     id - A specific post ID to return. Use instead of start, num, or type.
    #     filter - Alternate filter to run on the text content. Allowed values:
    #         text - Plain text only. No HTML.
    #         none - No post-processing. Output exactly what the author entered. (Note: Some authors write in Markdown, which will not be converted to HTML when this option is used.)
    #     tagged - Return posts with this tag in reverse-chronological order (newest first). Optionally specify chrono=1 to sort in chronological order (oldest first).
    #     search - Search for posts with this query.
    #     state (Authenticated read required) - Specify one of the values draft, queue, or submission to list posts in the respective state.
      post url_for(:read, args.delete(:json)), @auth.merge( args )
    else # public
      get url_for(:read)
    end
  end
  
  def pages args={}
    if args.any?
      post url_for(:pages), @auth
    else #public
      get url_for(:pages)
    end
  end


  ### Authenticated API calls
  ###########################
  
  def dashboard args={}
    { :likes => '1' }.merge( args )
  #   start, num, type, filter (optional) - Identical to /api/read above. The maximum value of start is 250.
  # max num = 51
    post url_for(:dashboard, args.delete(:json)), @auth.merge( args )
  end

  def like post_id, reblog_key
    post url_for(:like), @auth.merge( :'post-id' => post_id, :'reblog-key' => reblog_key )
  end

  def unlike post_id, reblog_key
    post url_for(:unlike), @auth.merge( :'post-id' => post_id, :'reblog-key' => reblog_key )
  end
  
  def reblog post_id, reblog_key, args={}
    # comment (optional) - Text, HTML, or Markdown string (see format) of the commentary added to the reblog. It will appear below the automatically generated reblogged-content structure. Up to 2000 characters allowed (as UTF-8 characters, not bytes). This field is not supported, and is ignored, for chat posts.
    # as (optional) - Reblog as a different format from the original post. text, link, and quote are supported.
    # The format and group parameters from /api/write are also supported. 
    post url_for(:reblog), @auth.merge( :'post-id' => post_id, :'reblog-key' => reblog_key ).merge( args )    
  end

  def write args={}
#         type - The post type.
#     (content parameters) - These vary by post type.
#     generator (optional) - A short description of the application making the request for tracking and statistics, such as "John's Widget 1.0". Must be 64 or fewer characters.
#     date (optional) - The post date, if different from now, in the blog's timezone. Most unambiguous formats are accepted, such as '2007-12-01 14:50:02'. Dates may not be in the future.
#     private (optional) - 1 or 0. Whether the post is private. Private posts only appear in the Dashboard or with authenticated links, and do not appear on the blog's main page.
#     tags (optional) - Comma-separated list of post tags. You may optionally enclose tags in double-quotes.
#     format (optional) - html or markdown.
#     group (optional) - Post this to a secondary blog on your account, e.g. mygroup.tumblr.com (for public groups only)
#     slug (optional) - A custom string to appear in the post's URL: myblog.tumblr.com/post/123456/this-string-right-here. URL-friendly formatting will be applied automatically. Maximum of 55 characters.
#     state (optional) - One of the following values:
#         published (default)
#         draft - Save in the tumblelog's Drafts folder for later publishing.
#         submission - Add to the tumblelog's Messages folder for consideration.
#         queue - Add to the tumblelog's queue for automatic publishing in a few minutes or hours. To publish at a specific time in the future instead, specify an additional publish-on parameter with the date expression in the tumblelog's local time (e.g. publish-on=2010-01-01T13:34:00). If the date format cannot be understood, a 401 error will be returned and the post will not be created.
# 
#     To change the state of an existing post, such as to switch from draft to published, follow the editing process and pass the new value as the state parameter.
# 
#     Note: If a post has previously been saved as a draft, queue, or submission post, it will be assigned a new post ID the first time it enters the published state.
#     send-to-twitter (optional, ignored on edits) - One of the following values, if the tumblelog has Twitter integration enabled:
#         no (default) - Do not send this post to Twitter.
#         auto - Send to Twitter with an automatically generated summary of the post.
#         (any other value) - A custom message to send to Twitter for this post.
# 
#     If this parameter is unspecified, API-created posts will be sent to Twitter if the "Send my Tumblr posts to Twitter" checkbox in the Customize screen is checked.
# 
# Post types
# 
# These are the valid values for the type parameter, with the associated content parameters that each type supports:
# 
#     regular - Requires at least one:
#         title
#         body (HTML allowed)
#     photo - Requires either source or data, but not both. If both are specified, source is used.
#         source - The URL of the photo to copy. This must be a web-accessible URL, not a local file or intranet location.
#         data - An image file. See File uploads below.
#         caption (optional, HTML allowed)
#         click-through-url (optional)
#     quote
#         quote
#         source (optional, HTML allowed)
#     link
#         name (optional)
#         url
#         description (optional, HTML allowed)
#     conversation
#         title (optional)
#         conversation
#     video - Requires either embed or data, but not both.
#         embed - Either the complete HTML code to embed the video, or the URL of a YouTube video page.
#         data - A video file for a Vimeo upload. See File uploads below.
#         title (optional) - Only applies to Vimeo uploads.
#         caption (optional, HTML allowed)
#     audio
#         data - An audio file. Must be MP3 or AIFF format. See File uploads below.
#         externally-hosted-url (optional, replaces data) - Create a post that uses this externally hosted audio-file URL instead of having Tumblr copy and host an uploaded file. Must be MP3 format. No size or duration limits are imposed on externally hosted files.
#         caption (optional, HTML allowed)
# 
# File uploads
# 
# File uploads can be done in a data parameter where specified above. You may use either of the common encoding methods:
# 
#     multipart/form-data method, like a file upload box in a web form. Maximum size:
#         50 MB for videos
#         10 MB for photos
#         10 MB for audio
#     This is recommended since there's much less overhead.
#     Normal POST method, in which the file's entire binary contents are URL-encoded like any other POST variable. Maximum size:
#         5 MB for videos
#         5 MB for photos
#         5 MB for audio
    post url_for(:write), @auth.merge( :'post-id' => post_id )
  end

  def update post_id, args={}
    write args.merge(:'post-id' => post_id )
  end
  
  def delete post_id
    post url_for(:delete), @auth.merge( :'post-id' => post_id )
  end
  
  def likes args={}
    # start, num, filter (optional) - Identical to /api/read above. The maximum value of start is 1000. 
    post url_for(:likes), @auth.merge( args )
  end
  
  def authenticate
    post url_for(:authenticate), @auth
  end
  
  ### Response/Parsing methods
  ##############################
  JSON_MATCHER = /^var \w+ = (.+);/

  def to_hash
    return unless @response
    if @response =~ JSON_MATCHER
      parse_json
    else
      XmlSimple.xml_in( @response )
    end
  end
  
  def success?
    return unless @response
    @response.code == 200
  end
  
  def failure?
    return unless @response
    !success?
  end

  private

  def get url
    @response = RestClient.get( url )
    to_hash if success?
  end

  def post url, args={}
    @response = RestClient.post( url, args )
    to_hash if success?      
  end
  
  def parse_json
    return unless @response
    JSON.parse( @response[JSON_MATCHER,1] )
  end
    
end
