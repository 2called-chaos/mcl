module Mcl
  class Handler
    module BookVerter
      def pageify page
        pc = page.strip.gsub("\n", ",").squeeze(" ").gsub("\\n", "\\\\\\\\n").gsub('"', '\"')
        "\"{\\\"text\\\":\\\"\\\",\\\"extra\\\":[#{pc}]}\""
      end

      def pageify_new page
        %{["", #{page.strip.gsub("\n", ",").squeeze(" ")}]}
      end

      def pagify_all *pages, fnew: false
        pages.map{|p| fnew ? pageify_new(p) : pageify(p) }.join(",")
      end

      def book who, title, pages, opts = {}
        opts = {author: "MCL"}.merge(opts)
        version_switch do |v|
          v.default do
            return %{/give #{who} written_book 1 0 {title:"#{title}",author:"#{opts[:author]}",pages:[#{pagify_all(*pages)}]}}
          end
          v.since("1.21") do
            return %{/give #{who} written_book[written_book_content={title:"#{title}",author:"#{opts[:author]}",pages:[#{pagify_all(*pages, fnew: true)}]}]}
          end
          v.since("1.13", "17w45a") do
            return %{/give #{who} written_book{title:"#{title}",author:"#{opts[:author]}",pages:[#{pagify_all(*pages)}]}}
          end
        end
      end
    end
  end
end
