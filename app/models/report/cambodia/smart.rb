require_relative '../base'

module Report
  module Cambodia
    class Smart < Report::Base
      def generate!
        workbook.add_worksheet(:name => "invoice") do |sheet|
          sheet.add_row([
            "Description", "Short Code", "Qty", "Unit Cost", "Amount", "Included Tax",
            "Specific Tax", "VAT", "Amount After Tax", "Revenue Share"
          ])
        end
        package.serialize("smart.xlsx")
      end
    end
  end
end
