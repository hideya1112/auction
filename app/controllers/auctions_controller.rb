class AuctionsController < ApplicationController
    def show
      @auction = Auction.first
    end
  
    def update
      @auction = Auction.find(params[:id])
  
      if params[:auction][:current_bid].to_f >= @auction.current_bid
        @auction.update(current_bid: params[:auction][:current_bid])
      else
        flash[:alert] = "入札金額は現在の金額より高くなければなりません"
        render :show
      end
    end
  end
