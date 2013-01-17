require 'api_spec_helper'

describe "Lectures API" do
  before do
    environment = Factory(:complete_environment)
    course = environment.courses.first
    space = course.spaces.first
    @subject = Factory(:subject, :owner => course.owner,
                       :space => space, :finalized => true)
    Factory(:lecture, :subject => @subject, :owner => course.owner)

    @application, @current_user, @token = generate_token(course.owner)
  end
  let(:base_params) do
    { :oauth_token => @token, :format => 'json' }
  end

  context "post /subjects/:subject_id/lectures" do
    context "when creating canvas" do
      let(:client_app) { @application }

      context "when the params is correct" do
        let(:params) do
          base_params.merge({:lecture => {
            :name => "My Goku Lecture",
            :type => "Canvas",
            :lectureable => { :client_application_id => client_app.id }
          }})
        end

        it "should return code 201 (created)" do
          post "api/subjects/#{@subject.id}/lectures", params
          response.code.should == '201'
        end

        it "should return the entity" do
          post "api/subjects/#{@subject.id}/lectures", params
          parse(response.body).should have_key('name')
        end
      end

      context "when the params aren't correct" do
        let(:params) { base_params.merge({ :lecture => { :name => "" } }) }

        it "should return code 422 when not valid" do
          post "api/subjects/#{@subject.id}/lectures", params
          response.code.should == '422'
        end

        it "should return the error explanation" do
          post "api/subjects/#{@subject.id}/lectures", params
          %w(name lectureable).each do |attr|
            parse(response.body).should have_key attr
          end
        end

        it "should return code 422 when not valid" do
          without_app = base_params.merge({:lecture => {
            :name => "My Goku Lecture",
            :type => "Canvas",
            :lectureable => { :client_application_id => "" }
          }})

          post "api/subjects/#{@subject.id}/lectures", without_app
          %w(lectureable lectureable.client_application).each do |attr|
            parse(response.body).should have_key attr
          end
        end
      end
    end

    context "when creating canvas with URL" do
      let(:client_app) { @application }

      context "when the params is correct" do
        let(:params) do
          base_params.merge({:lecture => {
            :name => "My Goku Lecture",
            :type => "Canvas",
            :lectureable => {
              :current_url => "http://google.com.br",
              :client_application_id => client_app.id
            }
          }})
        end

        it "should return code 201 (created)" do
          post "api/subjects/#{@subject.id}/lectures", params
          response.code.should == '201'
        end

        it "should return the entity" do
          post "api/subjects/#{@subject.id}/lectures", params
          parse(response.body)["lectureable"]["current_url"].
            should == "http://google.com.br"
        end
      end
    end
  end

  context "when GET /lectures/:id" do
    context "of any type" do
      let(:lecture) do
        Factory(:lecture, :lectureable => Factory(:document),
                :subject => @subject, :owner => @subject.owner)
      end

      before do
        mock_scribd_api
        get "/api/lectures/#{lecture.id}", base_params
      end

      it "should return status 200" do
        response.code.should == "200"
      end

      it "should have the correct properties" do
        resource = parse(response.body)
        %w(id name position rating view_count type lectureable created_at
          updated_at).each do |property|
            resource.should have_key property
          end
      end

      it "should have the correct links" do
        links = parse(response.body)['links'].collect { |l| l.fetch "rel" }
        %w(self self_link subject space course environment).each do |link|
          links.should include link
        end
      end
    end

    context "and is a Document" do
      let(:lecture) do
        Factory(:lecture, :lectureable => Factory(:document),
                :subject => @subject, :owner => @subject.owner)
      end

      before do
        mock_scribd_api
        get "/api/lectures/#{lecture.id}", base_params
      end

      it "lectureable should have the correct properties" do
        lectureable = parse(response.body)["lectureable"]
        lectureable.should have_key "mimetype"
      end

      it "lectureable should have the correct links" do
        lectureable = parse(response.body)["lectureable"]
        links = lectureable['links'].collect { |l| l.fetch "rel" }
        %w(raw scribd).each do |link|
            links.should include link
        end
      end
    end
  end
end
