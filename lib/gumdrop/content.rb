
module Gumdrop
  
  class Content
    
    attr_accessor :path, :level, :filename, :source_filename, :type, :ext, :uri, :slug, :template, :params
    
    def initialize(path, params={})
      @params= HashObject.new params
      @path= path
      @level= (@path.split('/').length - 2)
      @source_filename= File.basename path

      filename_parts= @source_filename.split('.')
      ext= filename_parts.pop
      while !Tilt[ext].nil?
        ext= filename_parts.pop
      end
      filename_parts << ext # push the last file ext back on there!
      @filename= filename_parts.join('.')

      path_parts= @path.split('/')
      path_parts.shift
      path_parts.pop
      path_parts.push @filename

      @type= File.extname @source_filename
      @ext= File.extname @filename
      @uri= path_parts.join('/')
      @slug=@uri.gsub('/', '-').gsub(@ext, '')
      @template= unless Tilt[path].nil?
        Tilt.new path
      else
        nil
      end
    end
    
    def render(ignore_layout=false, reset_context=true, locals={})
      if reset_context

        default_layout= (@ext == '.css' or @ext == '.js' or @ext == '.xml') ? nil : 'site'
        Context.reset_data 'current_depth'=>@level, 'current_slug'=>@slug, 'page'=>self, 'layout'=>default_layout, 'params'=>self.params
      end
      Context.set_content self, locals
      content= @template.render(Context) 
      return content if ignore_layout
      layout= Context.get_template()
      while !layout.nil?
        content = layout.template.render(Context, content:content) { content }
        layout= Context.get_template()
      end
      content
    end
    
    def renderTo(output_path, filters=[], opts={})
      return copyTo(output_path, opts) unless useLayout?
      Gumdrop.report " Rendering: #{@uri}", :warning
      output= render()
      filters.each {|f| output= f.call(output, self) }
      File.open output_path, 'w' do |f|
        f.write output
      end
    end
          
    
    def copyTo(output, layout=nil, opts={})
      do_copy= if File.exists? output
        !FileUtils.identical? @path, output
      else
        true
      end
      if do_copy
        Gumdrop.report "   Copying: #{@uri}", :warning
        FileUtils.cp_r @path, output, opts
      else
        Gumdrop.report "    (same): #{@uri}", :info
      end
    end
    
    def mtime
      if File.exists? @path
        File.new(@path).mtime
      else
        Time.now
      end
    end
    
    def useLayout?
      !@template.nil?
    end
    
    def to_s
      @uri
    end
    
  end
  
end
