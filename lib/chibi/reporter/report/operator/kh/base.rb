require 'axlsx'
require 'active_support/core_ext/string'

require_relative '../base'

module Chibi
  module Reporter
    module Report
      module Operator
        module Kh
          class Base < Operator::Base
            DEFAULT_FONT_SIZE = 10
            NUM_FMT_CURRENCY = 7
            NUM_FMT_INTEGER = 3

            LARGE_FONT_SIZE = 12
            HUGE_FONT_SIZE = 32

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

            def add_invoice(&block)
              workbook.add_worksheet(:name => "invoice") do |sheet|
                self.current_sheet = sheet
                configure_page
                add_invoice_sections
                yield if block_given?
              end
            end

            def add_invoice_sections
              add_logo
              add_title
              add_business_details
              add_services
              add_payment_instructions
            end

            def column_widths
              @column_widths ||= [14, 7.4, 9.3, 9.3, 9.3, 9.3, 7, 9.3, 9.3]
            end

            def configure_page
              current_sheet.column_widths(*column_widths)
              current_sheet.page_setup.set(:paper_width => "210mm", :paper_height => "297mm")
              current_sheet.page_margins do |margins|
                margins.left = 0.28
                margins.right = 0.12
                margins.top = 0.28
                margins.bottom = 0.85
              end
              current_sheet.header_footer do |header_footer|
                # this should be parameterized
                header_footer.odd_footer = "#{business_name} | T: #{business_phone} | E: #{business_email} | W: #{business_web}\n#{business_address}"
              end
            end

            def style_attributes
              return @style_attributes if @style_attributes
              @style_attributes = {}
              @style_attributes[:normal] = {:sz => DEFAULT_FONT_SIZE}
              @style_attributes[:bold] = {:b => true}
              @style_attributes[:gray] = {:bg_color => "CCCCCCCC"}
              @style_attributes[:date] = {:format_code => "dd/mm/yyyy"}
              @style_attributes[:currency] = {:num_fmt => NUM_FMT_CURRENCY}
              @style_attributes[:percentage] = {:num_fmt => Axlsx::NUM_FMT_PERCENT}
              @style_attributes[:integer] = {:num_fmt => NUM_FMT_INTEGER}
              @style_attributes[:border] = {:border => Axlsx::STYLE_THIN_BORDER}
              @style_attributes[:center] = {:alignment => {:horizontal => :center}}
              @style_attributes[:left] = {:alignment => {:horizontal => :left}}
              @style_attributes[:large] = {:sz => LARGE_FONT_SIZE}
              @style_attributes[:italic] = {:i => true}
              @style_attributes[:huge] = {:sz => HUGE_FONT_SIZE}
              @style_attributes
            end

            def styles
              return @styles if @styles
              @styles = {}
              add_style
              add_style(:left)
              add_style(:bold)
              add_style(:bold, :left)
              add_style(:bold, :gray)
              add_style(:bold, :date)
              add_style(:border)
              add_style(:bold, :gray, :border)
              add_style(:bold, :gray, :center, :border)
              add_style(:currency, :border)
              add_style(:percentage, :border)
              add_style(:integer, :border)
              add_style(:large, :italic, :center)
              add_style(:huge, :bold, :center)
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
              options = row_styles.extract_options!
              row_styles.map { |row_style| style(([row_style] + [options[:additional_styles]]).flatten.compact) }
            end

            def style_attribute(*styles)
              style_attribute = {}
              styles.each do |style|
                style_attribute.merge!(style_attributes[style])
              end
              style_attribute
            end

            def business_name
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_BUSINESS_NAME"] || super
            end

            def business_vat_tin
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_BUSINESS_VAT_TIN"] || super
            end

            def business_email
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_BUSINESS_EMAIL"] || super
            end

            def business_phone
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_BUSINESS_PHONE"] || super
            end

            def business_web
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_BUSINESS_WEB"] || super
            end

            def business_address
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_BUSINESS_ADDRESS"] || super
            end

            def vat_rate
              (ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_VAT_RATE"] || super).to_f
            end

            def specific_tax_rate
              (ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_SPECIFIC_TAX_RATE"] || super).to_f
            end

            def invoice_number
              "1"
            end

            def invoice_period
              "01/01/2014 - 31/01/2014"
            end

            def invoice_date
              Date::strptime(Date.today.strftime("%d-%m-%Y"), '%d-%m-%Y')
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
              add_row
              merge_current_row
              add_row(["Invoice"], :style => style(:huge, :bold, :center))
              add_row
            end

            def row_tabulated_datum(attribute, value = nil, options = {})
              attribute_title = "#{attribute.to_s.titleize}:" if attribute
              {:attribute => attribute_title, :value => value, :style => options[:style] || []}
            end

            def services
              data["services"]
            end

            def business_detail_rows
              @business_detail_rows ||= [
                {
                  :columns => [
                    row_tabulated_datum(:to, billing_name),
                    row_tabulated_datum(:from, business_name)
                  ]
                },
                {
                  :columns => [
                    row_tabulated_datum(:address, billing_address),
                    row_tabulated_datum(:invoice_no, invoice_number)
                  ],
                  :options => {:height => 48}
                },
                {
                  :columns => [
                    row_tabulated_datum(:attn, billing_attention),
                    row_tabulated_datum(:date, invoice_date, :style => :date)
                  ]
                },
                {
                  :columns => [
                    row_tabulated_datum(:vat_tin, billing_vat_tin),
                    row_tabulated_datum(:vat_tin, business_vat_tin)
                  ]
                },
                {
                  :columns => [
                    row_tabulated_datum(nil),
                    row_tabulated_datum(:period, invoice_period)
                  ]
                }
              ]
            end

            def add_row_tabulated_data(row_configurations)
              row_configurations.each do |row_configuration|
                row_styles = []
                metadata_columns = []
                row_configuration[:columns].each_with_index do |column_configuration, index|
                  metadata_columns << column_configuration[:attribute]
                  metadata_columns << column_configuration[:value]
                  row_styles       << [nil]
                  row_styles       << ([:bold] << column_configuration[:style]).flatten

                  # column separators
                  metadata_columns << nil << nil
                  row_styles       << nil << nil
                end
                metadata_columns.pop until metadata_columns.last
                row_styles.pop until row_styles.last
                add_row(
                  metadata_columns,
                  (row_configuration[:options] || {}).merge(:style => row_style(*row_styles))
                )
              end
            end

            def add_business_details
              add_section_header(:business_details)
              add_row_tabulated_data(business_detail_rows)
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
              add_service_column(:specific_tax, :style => :percentage) do |service_data|
                service_data["specific_tax"] || specific_tax_rate
              end
              add_service_column(:vat, :style => :percentage) do |service_data|
                service_data["vat"] || vat_rate
              end
              add_service_column(:amount_excluding_tax) do
                "=#{service_cell(:amount_including_tax)}/(1+#{service_cell(:specific_tax)})/(1+#{service_cell(:vat)})"
              end
              add_service_column(:revenue_share) do |service_data|
                "=#{service_cell(:amount_excluding_tax)} * #{service_data['revenue_share']}"
              end
              @service_column_data
            end

            def service_totals
              @service_totals ||= {
                :sub_total => {
                  :height => 25,
                  :columns => [
                    {:header => true},
                    {
                      :value => Proc.new { |metadata|
                        "=sum(#{service_cell(:amount_excluding_tax, metadata[:start_services_row])}:#{service_cell(:amount_excluding_tax, metadata[:end_services_row])})"
                      },
                      :position => service_column(:amount_excluding_tax)
                    },
                    {
                      :value => Proc.new { |metadata|
                        "=sum(#{service_cell(:revenue_share, metadata[:start_services_row])}:#{service_cell(:revenue_share, metadata[:end_services_row])})"
                      },
                      :position => service_column(:revenue_share)
                    }
                  ]
                },
                :vat => {
                  :height => 25,
                  :columns => [
                    {:value => "VAT #{(vat_rate * 100).to_i}%", :header => true},
                    {
                      :value => Proc.new { |metadata|
                        "=#{service_cell(:revenue_share, metadata[:sub_total_row])}*#{vat_rate}"
                      },
                      :position => service_column(:revenue_share)
                    }
                  ]
                },
                :total => {
                  :style => [:bold, :gray],
                  :columns => [
                    {:header => true},
                    {
                      :value => Proc.new { |metadata|
                        "=sum(#{service_cell(:revenue_share, metadata[:sub_total_row])}:#{service_cell(:revenue_share, metadata[:vat_row])})"
                      },
                      :position => service_column(:revenue_share),
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
              worksheet_column(service_column(key)) + (row || current_row).to_s
            end

            def service_column(key)
              service_column_data.keys.index(key)
            end

            def total_service_columns
              service_column_data.count
            end

            def service_totals_row_number(key)
              current_row + service_totals.keys.index(key)
            end

            def add_services
              add_section_header(:services)
              add_table_row(service_columns(:header), :header => true)
              start_services_row = current_row
              services.each do |service, service_data|
                add_table_row(service_columns(:value, service_data), :styles => service_columns(:style))
              end
              add_service_totals(start_services_row)
            end

            def add_service_totals(start_services_row)
              totals_metadata = {
                :start_services_row => start_services_row,
                :end_services_row => current_row - 1,
                :sub_total_row => service_totals_row_number(:sub_total),
                :vat_row => service_totals_row_number(:vat)
              }

              service_totals.each do |name, total_row|
                row = Array.new(total_service_columns, nil)
                row_style = total_row.delete(:style)
                styles = row_style ? Array.new(total_service_columns, row_style) : row.dup
                columns = total_row.delete(:columns)
                columns.each_with_index do |cell, index|
                  value = cell[:header] ? column_header(name, :header => cell[:value]) : cell[:value].call(totals_metadata)
                  row[cell[:position] || index] = value
                end
                add_table_row(row, {:styles => styles}.merge(total_row))
              end
            end

            def add_table_row(row = [], options = {})
              styles = options.delete(:styles)
              default_row_options = options.delete(:header) ? {:height => 37, :style => style(:bold, :gray, :center, *table_styles)} : {:style => row_style(*styles, :additional_styles => table_styles)}
              add_row(row, default_row_options.merge(options))
            end

            def table_styles
              @table_styles ||= [:border]
            end

            def payment_instruction_rows
              @payment_instruction_rows ||= [
                {:columns => [payment_instruction(:bank_name)]},
                {:columns => [payment_instruction(:account_name)]},
                {:columns => [payment_instruction(:account_number, :style => :left)]},
                {:columns => [payment_instruction(:swift_code)]},
                {:columns => [payment_instruction(:bank_address)], :options => {:height => 48}}
              ]
            end

            def payment_instruction(name, options = {})
              row_tabulated_datum(name, payment_instructions[name.to_s], options)
            end

            def payment_instructions
              data["payment_instructions"]
            end

            def add_payment_instructions
              add_section_header(:payment_instructions)
              add_row_tabulated_data(payment_instruction_rows)
            end

            def add_row(row = [], options = {})
              options[:style] ||= style
              current_sheet.add_row(row, options)
              increment_row!
            end

            def add_section_header(title)
              add_row
              merge_current_row
              add_row([title.to_s.titleize], :style => style(:large, :italic, :center))
              add_row([], :height => 7)
            end

            def merge_current_row
              current_sheet.merge_cells(
                worksheet_column(0) + current_row.to_s + ":" + worksheet_column(column_widths.count - 1) + current_row.to_s
              )
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
  end
end
