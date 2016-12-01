
module Api::V1
  class PostsController < ApiController
    before_action :set_post, only: [:show, :update, :destroy, :react]
    before_action :authenticate_current_user, only: [:create, :update, :destroy, :react, :show, :index]
  
    # GET /posts
    def index
      render json: Post.all, current_user_id: @current_user.id
    end
  
    # GET /posts/1
    def show
      render_as_user(@post)
    end
  
    # POST /posts
    def create
      @post = Post.new(user_id: @current_user.id, content: params[:content])
  
      if @post.save
        render json: @post, status: :created
      else
        render json: @post.errors, status: :unprocessable_entity
      end
    end
    
    # POST /posts/1/react
    def react
      type = params[:reaction]
      action = params[:desired]
      if action == "react"
        if type == "wow"
          wow = WowReaction.new(post_id: @post.id, user_id: @current_user.id)
          if wow.save
            render_as_user(@post)
          else
            render json: wow.errors, status: :unprocessable_entity
          end
        elsif type == "like"
          like = LikeReaction.new(post_id: @post.id, user_id: @current_user.id)
          if like.save
            render_as_user(@post)
          else
            render json: like.errors, status: :unprocessable_entity
          end
        end
      else
        if type == "wow"
          if WowReaction.destroy_all(post_id: @post.id, user_id: @current_user.id)
            render_as_user(@post)
          else
            render json: {type: "unreact", success: "false"}
          end
        elsif type == "like"
          if LikeReaction.destroy_all(post_id: @post.id, user_id: @current_user.id)
            render_as_user(@post)
          else
            render json: {type: "unreact", success: "false"}
          end
        end
      end
    end
  
    # PATCH/PUT /posts/1
    def update
      if @post.user_id == @current_user.id && @post.update(post_params)
        render_as_user(@post)
      else
        render json: @post.errors, status: :unprocessable_entity
      end
    end
  
    # DELETE /posts/1
    def destroy
      if @post.user_id == @current_user.id
        @post.destroy
      end
    end
  
    private
      # Use callbacks to share common setup or constraints between actions.
      def set_post
        postID = params[:id]
        @post = Rails.cache.fetch("posts/#{postID}", expires_in: 24.hours) do
          puts "cache: fetching post #{postID}"
          Post.find(postID)
        end
      end
  
      # Only allow a trusted parameter "white list" through.
      def post_params
        params.fetch(:post, {})
      end
  end
end
