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

            attr_accessor :month, :year, :invoice_number, :data, :io_stream
            attr_accessor :current_sheet

            def initialize(options = {})
              self.month = options[:month]
              self.year = options[:year]
              self.invoice_number = options[:invoice_number]
              self.data = options[:data]
            end

            def generate!
              add_invoice
              add_service_details
              self.io_stream = package.to_stream
            end

            def mime_type
              "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            end

            def suggested_filename
              sanitize(File.join(year.to_s, invoice_month.strftime("%m_%B"), filename))
            end

            def self.enabled?(flag)
              flag.to_i == 1
            end

            private

            def aws_s3_root_directory(*parts)
              super(ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_AWS_S3_ROOT_DIRECTORY"], *parts)
            end

            def filename
              text = []
              text << human_name
              text << business_name
              text << "invoice_and_report"
              text << invoice_period
              text.join("_") << ".xlsx"
            end

            def sanitize(text)
              text.gsub(/\s+/, '_').downcase
            end

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

            def add_service_details
              services.each do |service, service_metadata|
                workbook.add_worksheet(:name => service_metadata["name"]) do |sheet|
                  self.current_sheet = sheet
                  headers = service_metadata["headers"]
                  add_row(headers)

                  service_metadata["data"].each do |data_row|
                    add_row(
                      service_details_data_row(data_row, headers),
                      :widths => service_details_row_widths(headers),
                      :style => service_details_row_style(headers)
                    )
                  end
                end
              end
            end

            def service_details_data_row(service_data_row, headers)
              data_row = service_data_row.dup
              data_row.each_with_index do |data_cell, index|
                if timestamp_column?(headers, index)
                  time = Time.parse(data_cell)
                  spreadsheet_time = Time.at(time.to_f + time.utc_offset)
                  data_row[index] = spreadsheet_time
                end
              end
              data_row
            end

            def service_details_row_widths(headers)
              return nil if headers.empty?
              row_widths = Array.new(headers.count, :auto)
              row_widths.each_with_index do |row_width, index|
                row_widths[index] = 20 if timestamp_column?(headers, index)
              end
              row_widths
            end

            def service_details_row_style(headers)
              return nil if headers.empty?

              row_styles = Array.new(headers.count, nil)
              row_styles.each_with_index do |row_style, index|
                row_styles[index] = :date_time if timestamp_column?(headers, index)
              end

              row_style(*row_styles)
            end

            def timestamp_column?(headers, index)
              headers[index] == "timestamp"
            end

            def add_invoice_sections
              add_logo
              add_title
              add_business_details
              add_services
              add_payment_instructions
              add_verification
            end

            def column_widths
              @column_widths ||= [14, 9, 7.4, 7.4, 14, 9.3, 4, 9, 9]
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
                header_footer.odd_footer = "#{business_name} | T: #{business_phone} | E: #{business_email} | W: #{business_web}\n#{business_address}"
              end
            end

            def style_attributes
              return @style_attributes if @style_attributes
              @style_attributes = {}
              @style_attributes[:normal] = {:sz => DEFAULT_FONT_SIZE}
              @style_attributes[:bold] = {:b => true}
              @style_attributes[:gray] = {:bg_color => "CCCCCCCC"}
              @style_attributes[:date_time] = { :format_code => "dd/mm/yyyy hh:mm:ss" }
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
              add_style(:date_time)
              add_style(:bold, :left)
              add_style(:bold, :gray)
              add_style(:bold, :left, :date)
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

            # business specific details

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

            def business_logo_path
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_BUSINESS_LOGO_PATH"] || super
            end

            # billing details

            def bank_name
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_BUSINESS_BANK_NAME"] || super
            end

            def bank_account_name
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_BUSINESS_BANK_ACCOUNT_NAME"] || super
            end

            def bank_account_number
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_BUSINESS_BANK_ACCOUNT_NUMBER"] || super
            end

            def bank_swift_code
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_BUSINESS_BANK_SWIFT_CODE"] || super
            end

            def bank_address
              ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_BUSINESS_BANK_ADDRESS"] || super
            end

            def vat_rate
              (ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_VAT_RATE"] || super).to_f
            end

            def specific_tax_rate
              (ENV["CHIBI_REPORTER_REPORT_OPERATOR_KH_SPECIFIC_TAX_RATE"] || super).to_f
            end

            def invoice_period
              invoice_month.strftime("%B %Y")
            end

            def invoice_month
              Time.new(year, month)
            end

            def invoice_date
              Date::strptime(Date.today.strftime("%d-%m-%Y"), '%d-%m-%Y')
            end

            # google drive

            def add_blank_rows(count)
              count.times { add_row }
            end

            def add_logo
              current_sheet.add_image(:image_src => business_logo_path) do |image|
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
                  row_styles       << ([:bold, :left] << column_configuration[:style]).flatten

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
                {:columns => [row_tabulated_datum(:bank_name, bank_name)]},
                {:columns => [row_tabulated_datum(:account_name, bank_account_name)]},
                {:columns => [row_tabulated_datum(:account_number, bank_account_number)]},
                {:columns => [row_tabulated_datum(:swift_code, bank_swift_code)]},
                {:columns => [row_tabulated_datum(:bank_address, bank_address)], :options => {:height => 48}}
              ]
            end

            def add_payment_instructions
              add_section_header(:payment_instructions)
              add_row_tabulated_data(payment_instruction_rows)
            end

            def add_verification
              add_section_header(:verification)
              add_row_tabulated_data(verification_rows)
            end

            def verification_rows
              @verification_rows ||= [
                {:columns => [row_tabulated_datum(:issued_by), row_tabulated_datum(:checked_by), row_tabulated_datum(:approved_by)]},
                {:columns => [row_tabulated_datum(:name), row_tabulated_datum(:name), row_tabulated_datum(:name)]},
                {:columns => [row_tabulated_datum(:date), row_tabulated_datum(:date), row_tabulated_datum(:date)]}
              ]
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
