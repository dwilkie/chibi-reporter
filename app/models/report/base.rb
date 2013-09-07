require 'axlsx'

module Report
  class Base
    attr_accessor :data

    def initialize(options = {})
      self.data = options[:data]
    end

    private

    def workbook
      @workbook ||= package.workbook
    end

    def package
      @package ||= Axlsx::Package.new
    end
  end
end
