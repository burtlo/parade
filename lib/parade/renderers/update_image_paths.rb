module Parade
  module Renderers

    #
    # UpdateImagePaths is used to ensure the img source paths in the HTML
    # content is properly prefaced with the "image" path as that is necessary
    # for the Sinatra server to properly know that it is to return an image.
    #
    # Additional processing of the image is provided if RMagick has been
    # installed. Namely it sets the size correctly.
    #
    class UpdateImagePaths

      attr_accessor :root_path

      def initialize(params = {})
        params.each {|k,v| send("#{k}=",v) if respond_to? "#{k}=" }
      end

      #
      # @param [String] content HTML content that is parsed for image srcs
      # @param [Hash] options additional parameters, at the moment it is unused.
      #
      def self.render(content,options = {})
        self.new(options).render(content)
      end

      def render(content,options = {})
        render_root_path = options[:root_path] || root_path || "."

        content.gsub(/img src=["'](?!https?:\/\/)\/?([^\/].*?)["']/) do |image_source|
          image_name = Regexp.last_match(1)

          html_image_path = File.join("/","image",image_name)
          updated_image_source = %{img src="#{html_image_path}"}

          html_asset_path = File.join(render_root_path,image_name)
          width, height = get_image_size(html_asset_path)
          updated_image_source << %( width="#{width}" height="#{height}") if width and height

          updated_image_source
        end
      end

      def get_image_size(path) ; end

      if defined?(Magick)

        def get_image_size(path)
          return unless File.exists?(path)

          unless cached_image_size.key?(path)

            image = Magick::Image.ping(path).first

            # # don't set a size for svgs so they can expand to fit their container
            if image.mime_type == 'image/svg+xml'
              cached_image_size[path] = [nil, nil]
            else
              cached_image_size[path] = [image.columns, image.rows]
            end

          end
          cached_image_size[path]
        end

        def cached_image_size
          @cached_image_size ||= {}
        end


      end

    end

  end
end
