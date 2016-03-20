module Mcl
  class Handler
    module BookVerter
      def pageify page
        '"{\"text\":\"\",\"extra\":[%%P%%]}"'.gsub('%%P%%', page.strip.gsub("\n", ",").squeeze(" ").gsub('"', '\"'))
      end

      def pagify_all *pages
        pages.map{|p| pageify(p) }.join(",")
      end

      def book who, title, pages, opts = {}
        opts = {author: "MCL"}.merge(opts)
        %{/give #{who} written_book 1 0 {title:"#{title}",author:"#{opts[:author]}",pages:[#{pagify_all(*pages)}]}}
      end
    end
  end
end
