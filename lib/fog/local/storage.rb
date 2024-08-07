module Fog
  module Local
    class Storage < Fog::Service
      autoload :Directories, 'fog/local/models/directories'
      autoload :Directory, 'fog/local/models/directory'
      autoload :File, 'fog/local/models/file'
      autoload :Files, 'fog/local/models/files'

      requires :local_root
      recognizes :endpoint, :scheme, :host, :port, :path

      model_path 'fog/local/models'
      collection  :directories
      model       :directory
      model       :file
      collection  :files

      require 'uri'

      class Mock
        attr_reader :endpoint

        def self.data
          @data ||= Hash.new do |hash, key|
            hash[key] = {}
          end
        end

        def self.reset
          @data = nil
        end

        def initialize(options={})
          Fog::Mock.not_implemented

          @local_root = ::File.expand_path(options[:local_root])

          @endpoint = options[:endpoint] || build_endpoint_from_options(options)
        end

        def data
          self.class.data[@local_root]
        end

        def local_root
          @local_root
        end

        def path_to(partial)
          ::File.join(@local_root, partial)
        end

        def reset_data
          self.class.data.delete(@local_root)
        end

        private
        def build_endpoint_from_options(options)
          return unless options[:host]

          URI::Generic.build(options).to_s
        end
      end

      class Real
        attr_reader :endpoint

        def initialize(options={})
          @local_root = ::File.expand_path(options[:local_root])

          @endpoint = options[:endpoint] || build_endpoint_from_options(options)
        end

        def local_root
          @local_root
        end

        def path_to(partial)
          ::File.join(@local_root, partial)
        end

        def get_bucket(bucket_name, options = {})
          path = path_to(::File.join(bucket_name, options[:prefix].to_s))
          files = Dir.glob("#{path}/*")
          ::JSON.parse({ body: { Contents: files } }.to_json, object_class: OpenStruct)
        end

        def copy_object(source_directory_name, source_object_name, target_directory_name, target_object_name, options={})
          source_path = path_to(::File.join(source_directory_name, source_object_name))
          target_path = path_to(::File.join(target_directory_name, target_object_name))
          ::FileUtils.mkdir_p(::File.dirname(target_path))
          ::FileUtils.copy_file(source_path, target_path)
        end

        private
        def build_endpoint_from_options(options)
          return unless options[:host]

          URI::Generic.build(options).to_s
        end
      end
    end
  end
end
