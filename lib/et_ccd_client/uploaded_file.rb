module EtCcdClient
  class UploadedFile
    # The filename, *not* including the path, of the "uploaded" file
    attr_reader :original_filename

    # The content type of the "uploaded" file
    attr_accessor :content_type

    def initialize(path, content_type: "text/plain", binary: false, original_filename: File.basename(path))
      raise "#{path} file does not exist" unless ::File.exist?(path)
      @content_type = content_type
      @original_filename = original_filename
      @tempfile = Tempfile.new([@original_filename, ::File.extname(path)], encoding: Encoding::BINARY)
      @tempfile.binmode if binary
      FileUtils.copy_file(path, @tempfile.path)
    end

    def path
      @tempfile.path
    end
    alias_method :local_path, :path

    def respond_to?(*args)
      super or @tempfile.respond_to?(*args)
    end

    def method_missing(method_name, *args, &block) #:nodoc:
      @tempfile.__send__(method_name, *args, &block)
    end
  end

end
