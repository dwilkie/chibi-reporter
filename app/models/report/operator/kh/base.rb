require 'axlsx'
require 'active_support/core_ext/string'
require_relative '../base'

module Report
  module Operator
    module Kh
      class Base < Operator::Base
        DEFAULT_FONT_SIZE = 10

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
            configure_page
            yield
          end
        end

        def configure_page
          current_sheet.column_widths(9.3, 9.3, 9.3, nil, nil, nil, nil, nil, nil)
          current_sheet.page_setup.set(:paper_width => "210mm", :paper_height => "297mm")
          current_sheet.page_margins do |margins|
            margins.left = 0.28
            margins.right = 0.28
            margins.top = 0.28
            margins.bottom = 0.28
          end
        end

        def styles
          @styles ||= {}
          @styles[:normal] ||= current_sheet.styles.add_style(style_attribute(:normal))
          @styles[:normal_bold] ||= current_sheet.styles.add_style(
            style_attribute(:normal, :bold)
          )
          @styles[:normal_bold_date] ||= current_sheet.styles.add_style(
            style_attribute(:normal, :bold, :date)
          )
          @styles
        end

        def style(*style_keys)
          styles[style_keys.join("_").to_sym]
        end

        def row_style(*row_styles)
          row_styles.map { |row_style| style(row_style) }
        end

        def style_attributes
          @style_attributes ||= {}
          @style_attributes[:normal] ||= {:sz => DEFAULT_FONT_SIZE}
          @style_attributes[:bold] ||= {:b => true}
          @style_attributes[:date] ||= {:format_code => "dd/mm/yyyy"}
          @style_attributes
        end

        def style_attribute(*styles)
          style_attribute = {}
          styles.each do |style|
            style_attribute.merge!(style_attributes[style])
          end
          style_attribute
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
          Date::strptime(Date.today.strftime("%d-%m-%Y"), '%d-%m-%Y')
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

        def report_metadata(attribute, value, options = {})
          attribute_title = "#{attribute.to_s.titleize}:" if attribute
          {:attribute => attribute_title, :value => value, :style => options[:style] || []}
        end

        def report_metadata_rows
          @report_metadata_rows ||= [
            # metadata row
            {
              :columns => [
                report_metadata(:to, operator_business_name),
                report_metadata(:from, business_name)
              ]
            },
            # metadata row
            {
              :columns => [
                report_metadata(:address, operator_address),
                report_metadata(:invoice_no, invoice_number)
              ],
              :options => {:height => 48}
            },
            # metadata row
            {
              :columns => [
                report_metadata(:attn, operator_attention),
                report_metadata(:date, invoice_date, :style => :date)
              ]
            },
            # metadata row
            {
              :columns => [
                report_metadata(:vat_tin, operator_vat_tin),
                report_metadata(:vat_tin, business_vat_tin)
              ]
            },
            # metadata row
            {
              :columns => [
                report_metadata(nil, nil),
                report_metadata(:period, invoice_period)
              ]
            }
          ]
        end

        def add_report_metadata
          report_metadata_rows.each do |report_metadata_row|
            row_styles = []
            metadata_columns = []
            report_metadata_row[:columns].each_with_index do |report_metadata, index|
              metadata_columns << report_metadata[:attribute]
              metadata_columns << report_metadata[:value]
              row_styles       << [:normal]
              row_styles       << ([:normal, :bold] << report_metadata[:style]).flatten

              # column separators
              metadata_columns << nil << nil
              row_styles       << nil << nil
            end
            metadata_columns.pop until metadata_columns.last
            row_styles.pop until row_styles.last
            add_row(
              metadata_columns,
              (report_metadata_row[:options] || {}).merge(:style => row_style(*row_styles))
            )
          end
        end

        def add_table
          add_row([
            "Description", "Short\nCode", "Qty", "Unit\nCost", "Amount", "Included\nTax",
            "Specific\nTax", "VAT", "Amount\nAfter\nTax", "Revenue\nShare"
          ], :height => 37, :style => style(:normal, :bold))
        end

        def add_row(row = [], options = {})
          options[:style] ||= style(:normal)
          current_sheet.add_row(row, options)
        end
      end
    end
  end
end
