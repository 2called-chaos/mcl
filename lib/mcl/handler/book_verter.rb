module Mcl
  class Handler
    module BookVerter
      def pageify page
        pc = page.strip.gsub("\n", ",").squeeze(" ").gsub("\\n", "\\\\\\\\n").gsub('"', '\"')
        "\"{\\\"text\\\":\\\"\\\",\\\"extra\\\":[#{pc}]}\""
      end

      def pagify_all *pages
        pages.map{|p| pageify(p) }.join(",")
      end

      def book who, title, pages, opts = {}
        opts = {author: "MCL"}.merge(opts)
        version_switch do |v|
          v.default do
            return %{/give #{who} written_book 1 0 {title:"#{title}",author:"#{opts[:author]}",pages:[#{pagify_all(*pages)}]}}
          end
          v.since("1.13", "17w45a") do
            return %{/give #{who} written_book{title:"#{title}",author:"#{opts[:author]}",pages:[#{pagify_all(*pages)}]}}
          end
        end
      end
    end
  end
end
