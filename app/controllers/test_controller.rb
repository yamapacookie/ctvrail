class TestController < ApplicationController
    def test
        @clist = Clist.all
    end
end
