require File.expand_path("../../test_helper", __FILE__)

class UserFriendshipsControllerTest < ActionController::TestCase

  context "#index" do
    context "when not logged in" do
      should "redirect to the login page" do
        get :index
        assert_response :redirect
      end
    end 

    context "when logged in" do
      setup do 
        @friendship1 = create(:pending_user_friendship, user: users(:christina), friend: create(:user, first_name: 'Pending', last_name: 'Friend'))
        @friendship2 = create(:accepted_user_friendship, user: users(:christina), friend: create(:user, first_name: 'Active', last_name: 'Friend'))

        sign_in users(:christina)
        get :index
      end

      should "get the index page without error" do
        assert_response :success
      end

      should "assign user_friendships" do
        assert assigns(:user_friendships)
      end

      should "display friend's names" do
        assert_match /Pending/, response.body
        assert_match /Active/, response.body
      end

      should "display pending friend information" do
        assert_select "#user_friendship_#{@friendship1.id}" do
          assert_select "em", "Friendship is pending."
        end
      end

      should "display date information on accepted friendship" do
        assert_select "#user_friendship_#{@friendship2.id}" do
          assert_select "em", "Friendship started #{@friendship2.updated_at}."
        end
      end


    end
  end

  context "#new" do
    context "when not logged in" do
      should "redirect to the login page" do
        get :new
        assert_response :redirect
      end
    end

  context "when logged in" do
      setup do
        sign_in users(:christina)
      end

      should "get new and return success" do
        get :new
        assert_response :success
      end

      should "set a flash error if the friend_id params is missing" do
        get :new, {}
        assert_equal "Friend required", flash[:error]
      end

      should "display the friend's name" do
        get :new, friend_id: users(:will)
        assert_match /#{users(:will).full_name}/, response.body
      end

      should "assign a new user friendship" do
        get :new, friend_id: users(:will)
        assert assigns(:user_friendship)
      end

      should "assign a new user friendship to the correct friend" do
        get :new, friend_id: users(:will)
        assert_equal users(:will), assigns(:user_friendship).friend
      end

      should "assign a new user friendship to the currently logged in user" do
        get :new, friend_id: users(:will)
        assert_equal users(:christina), assigns(:user_friendship).user
      end

      should "return a 404 status if no friend is found" do
        get :new, friend_id: 'invalid'
        assert_response :not_found
      end

      should "ask if you really want to request this friendship" do
        get :new, friend_id: users(:will)
        assert_match /Are you SURE you want to friend that dweeb #{users(:will).full_name}?/, response.body
      end
    end
  end

  context "#create" do
    context "when not logged in" do
      should "redirect to login page" do
        get :new
        assert_response :redirect
        assert_redirected_to login_path
      end
    end

    context "when logged in" do
      setup do
        sign_in users(:christina)
      end

    context "with no friend_id" do
      setup do
        post :create
      end
    
      should "set the flash error message" do
        assert !flash[:error].empty?
      end

      should "redirect to the site root" do
        assert_redirected_to root_path
      end
    end  

    context "with a valid friend_id" do
      setup do
        post :create, user_friendship: { friend_id: users(:will) }
      end

      should "assign a friend object" do
        assert assigns(:friend)
        assert_equal users(:will), assigns(:friend)
      end

      should "assign a user_friendship object" do
        assert assigns(:user_friendship)
        assert_equal users(:christina), assigns(:user_friendship).user
        assert_equal users(:will), assigns(:user_friendship).friend
      end

      should "create a friendship" do
        assert users(:christina).pending_friends.include?(users(:will))
      end

      should "redirect to the profile page of the friend" do
        assert_response :redirect
        assert_redirected_to profile_path(users(:will))
      end

      should "set the flash success message" do
        assert flash[:success]
        assert_equal "You are now friends with #{users(:will).full_name}", flash[:success]
      end
    end
   end
  end
end
