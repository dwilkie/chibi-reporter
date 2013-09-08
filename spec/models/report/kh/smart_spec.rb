require 'spec_helper'
require './app/models/report/kh/smart'

module Report
  module Kh
    #https://github.com/rails/rails/blob/41a398f859cc46430cb3b655d44c0cb3b41e42ae/activerecord/lib/active_record/inheritance.rb
    describe Smart, :focus do
      describe "#generate!" do
        it "should do something" do
          subject.generate!
          File.should exist("smart.xlsx")
        end
      end
    end
  end
end
