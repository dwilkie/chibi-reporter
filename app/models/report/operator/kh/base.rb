require 'axlsx'
require_relative '../base'

module Report
  module Operator
    module Kh
      class Base < Operator::Base
        attr_accessor :data
        attr_accessor :current_sheet

        def initialize(options = {})
          self.data = options[:data]
        end

        private

        def workbook
          @workbook ||= package.workbook
        end

        def package
          @package ||= Axlsx::Package.new
          @package.use_autowidth = false
          @package
        end

        def add_worksheet(&block)
          workbook.add_worksheet(:name => "invoice") do |sheet|
            self.current_sheet = sheet
            current_sheet.column_widths(9.3, 9.3, 9.3, nil, nil, nil, nil, nil, nil)
            current_sheet.page_setup.set(:paper_width => "210mm", :paper_height => "297mm")
            current_sheet.page_margins do |margins|
              margins.left = 0.28
              margins.right = 0.28
              margins.top = 0.28
              margins.bottom = 0.28
            end
            yield
          end
        end

        def normal_style
          @normal_style ||= current_sheet.styles.add_style(:sz => 10)
        end

        def business_name
          "Chatterbox Dating Mobile"
        end

        def business_vat_tin
          "107020858"
        end

        def invoice_number
          "1"
        end

        def invoice_date
          Date.today
        end

        def invoice_period
          "01/01/2014 - 31/01/2014"
        end

        def add_blank_rows(count)
          count.times { add_row }
        end

        def add_logo
          #img = "https://s3.amazonaws.com/chibimp3/chibi_reporter/images/logo_with_tagline.png"
          img = File.expand_path("logo_with_tagline.png")
          current_sheet.add_image(:image_src => img) do |image|
            image.width = 160
            image.height = 100
            image.start_at(7, 0)
          end
        end

        def add_title
          current_sheet.merge_cells("A5:I5")
        end

        def add_company_details
          add_company_details_row(["To:", operator_business_name], ["From:", business_name])
          add_company_details_row(
            ["Address:", operator_address], ["Invoice No:", invoice_number],
            :height => 48
          )
          add_company_details_row(["Attn:", operator_attention], ["Date", invoice_date])
          add_company_details_row(["VAT TIN:", operator_vat_tin], ["VAT TIN:", business_vat_tin])
          add_company_details_row(["", ""], ["Period", invoice_period])
        end

        def add_company_details_row(left, right, options = {})
          add_row(left + ["", ""] + right, options)
        end

        def add_row(row = [], options = {})
          options[:style] ||= normal_style
          current_sheet.add_row(row, options)
        end
      end
    end
  end
end
