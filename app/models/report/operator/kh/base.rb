require 'axlsx'
require 'active_support/core_ext/string'

require_relative '../base'

module Report
  module Operator
    module Kh
      class Base < Operator::Base
        DEFAULT_FONT_SIZE = 10
        NUM_FMT_CURRENCY = 7
        NUM_FMT_INTEGER = 3

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
          current_sheet.column_widths(14, 7.4, 9.3, 9.3, 9.3, 9.3, 7, 9.3, 9.3)
          current_sheet.page_setup.set(:paper_width => "210mm", :paper_height => "297mm")
          current_sheet.page_margins do |margins|
            margins.left = 0.28
            margins.right = 0.28
            margins.top = 0.28
            margins.bottom = 0.28
          end
        end

        def style_attributes
          return @style_attributes if @style_attributes
          @style_attributes = {}
          @style_attributes[:normal] = {:sz => DEFAULT_FONT_SIZE}
          @style_attributes[:bold] = {:b => true}
          @style_attributes[:date] = {:format_code => "dd/mm/yyyy"}
          @style_attributes[:currency] = {:num_fmt => NUM_FMT_CURRENCY}
          @style_attributes[:percentage] = {:num_fmt => Axlsx::NUM_FMT_PERCENT}
          @style_attributes[:integer] = {:num_fmt => NUM_FMT_INTEGER}
          @style_attributes
        end

        def styles
          return @styles if @styles
          @styles = {}
          add_style
          add_style(:bold)
          add_style(:bold, :date)
          add_style(:currency)
          add_style(:percentage)
          add_style(:integer)
          @styles
        end

        def style_key(keys)
          keys.join("_")
        end

        def add_style(*style_keys)
          attribute_keys = style_keys.dup
          attribute_keys.unshift(:normal)
          @styles[style_key(style_keys)] = current_sheet.styles.add_style(style_attribute(*attribute_keys))
        end

        def style(*style_keys)
          styles[style_key(style_keys)]
        end

        def row_style(*row_styles)
          row_styles.map { |row_style| style(row_style) }
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

        def vat_rate
          10
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

        def billing(key)
          data["billing"][key.to_s]
        end

        def services
          data["services"]
        end

        def report_metadata_rows
          @report_metadata_rows ||= [
            # metadata row
            {
              :columns => [
                report_metadata(:to, billing(:name)),
                report_metadata(:from, business_name)
              ]
            },
            # metadata row
            {
              :columns => [
                report_metadata(:address, billing(:address)),
                report_metadata(:invoice_no, invoice_number)
              ],
              :options => {:height => 48}
            },
            # metadata row
            {
              :columns => [
                report_metadata(:attn, billing(:attention)),
                report_metadata(:date, invoice_date, :style => :date)
              ]
            },
            # metadata row
            {
              :columns => [
                report_metadata(:vat_tin, billing(:vat_tin)),
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
              row_styles       << [nil]
              row_styles       << ([:bold] << report_metadata[:style]).flatten

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

        def add_service_column(name, options = {}, &block)
          @service_column_data.merge!(
            name => {
              :header => column_header(name, options),
              :value => block_given? ? block : Proc.new {|service_data| service_data[name.to_s]},
              :style => [options[:style]].flatten
            }
          )
        end

        def column_header(name, options = {})
          (options[:header] || name.to_s.titleize).gsub(/\s+/, "\n")
        end

        def service_column_data
          return @service_column_data if @service_column_data
          @service_column_data = {}
          add_service_column(:name, :header => "Description")
          add_service_column(:short_code)
          add_service_column(:quantity, :header => "Qty", :style => :integer)
          add_service_column(:unit_cost, :style => :currency)
          add_service_column(:amount_including_tax) do
            "=#{service_cell(:quantity)} * #{service_cell(:unit_cost)}"
          end
          add_service_column(:specific_tax, :style => :percentage)
          add_service_column(:vat, :style => :percentage)
          add_service_column(:amount_excluding_tax) do
            "=#{service_cell(:amount_including_tax)}/(1+#{service_cell(:specific_tax)})/(1+#{service_cell(:vat)})"
          end
          add_service_column(:revenue_share) do |service_data|
            "=#{service_cell(:amount_excluding_tax)}*#{service_data['revenue_share']}"
          end
          @service_column_data
        end

        def service_totals
          @service_totals ||= {
            :sub_total => {
              :columns => [
                {:header => true},
                {
                  :value => Proc.new { |metadata|
                    "=sum(#{service_cell(:amount_excluding_tax, metadata[:start_services_row])}:#{service_cell(:amount_excluding_tax, metadata[:end_services_row])})"
                  }
                },
                {
                  :value => Proc.new { |metadata|
                    "=sum(#{service_cell(:revenue_share, metadata[:start_services_row])}:#{service_cell(:revenue_share, metadata[:end_services_row])})"
                  }
                }
              ]
            },
            :vat => {
              :columns => [
                {:value => "VAT #{vat_rate}%", :header => true},
                {},
                {
                  :value => Proc.new { |metadata|
                    "=#{service_cell(:revenue_share, metadata[:sub_total_row])}*#{vat_rate}/100"
                  }
                }
              ]
            },
            :total => {
              :columns => [
                {:header => true},
                {},
                {
                  :value => Proc.new { |metadata|
                    "=sum(#{service_cell(:revenue_share, metadata[:sub_total_row])}:#{service_cell(:revenue_share, metadata[:vat_row])})"
                  }
                }
              ]
            }
          }
        end

        def service_columns(key, service_data = nil)
          service_column_data.map do |column, column_data|
            service_data ? column_data[key].call(service_data) : column_data[key]
          end
        end

        def service_cell(key, row = nil)
           worksheet_column(service_column_data.keys.index(key)) + (row || current_row).to_s
        end

        def service_totals_row_number(key)
          current_row + service_totals.keys.index(key)
        end

        def add_services_table
          add_row(service_columns(:header), :height => 37, :style => style(:bold))
          start_services_row = current_row
          services.each do |service, service_data|
            add_row(service_columns(:value, service_data), :style => row_style(*service_columns(:style)))
          end

          totals_metadata = {
            :start_services_row => start_services_row,
            :end_services_row => current_row - 1,
            :sub_total_row => service_totals_row_number(:sub_total),
            :vat_row => service_totals_row_number(:vat)
          }

          service_totals.each do |name, total_row|
            add_row(
              total_row[:columns].map do |cell|
                if cell[:header]
                  column_header(name, :header => cell[:value])
                else
                  cell[:value].call(totals_metadata) if cell[:value]
                end
              end
            )
          end
        end

        def add_row(row = [], options = {})
          options[:style] ||= style
          current_sheet.add_row(row, options)
          increment_row!
        end

        def current_row
          @current_row ||= 1
        end

        def increment_row!
          current_row
          @current_row += 1
        end

        def worksheet_column(index)
          worksheet_columns[index]
        end

        def worksheet_columns
          @worksheet_columns ||= ("a".."z").to_a
        end
      end
    end
  end
end
