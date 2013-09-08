require_relative '../chibi'

module Report
  module Kh
    class Smart < Report::Chibi
      def generate!
        workbook.add_worksheet(:name => "invoice") do |sheet|
          table_header = sheet.styles.add_style(:sz => 10)

          #img = "https://s3.amazonaws.com/chibimp3/chibi_reporter/images/logo_with_tagline.png"
          img = File.expand_path("logo_with_tagline.png")
          sheet.add_image(:image_src => img) do |image|
            image.width = 160
            image.height = 100
            image.start_at(7, 0)
          end

          sheet.merge_cells("A5:I5")

          5.times do
            sheet.add_row
          end

          sheet.add_row([
            "Description", "Short Code", "Qty", "Unit Cost", "Amount", "Included Tax",
            "Specific Tax", "VAT", "Amount After Tax", "Revenue Share"
          ], :style => table_header)
        end
        package.serialize("smart.xlsx")
      end
    end
  end
end
