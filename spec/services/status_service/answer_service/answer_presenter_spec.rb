# -*- encoding : utf-8 -*-
require 'spec_helper'

module StatusService
  module AnswerService
    describe AnswerPresenter do
      include ActionView::TestCase::Behavior

      let(:author) { FactoryGirl.build_stubbed(:user) }
      let(:user) { FactoryGirl.build_stubbed(:user) }
      let(:answer) do
        FactoryGirl.build_stubbed(:answer, user: author, in_response_to: status)
      end
      let(:status) { FactoryGirl.build_stubbed(:activity) }
      let(:notification) { AnswerNotification.new }
      subject { AnswerPresenter.new(notification: notification, template: view) }


      it "should degine author_link" do
        notification.stub(:answer).and_return(answer)
        subject.author_link.should =~ /href=\"#{view.user_url(author)}\"/
      end

      it "should define answer_link" do
        notification.stub(:answer).and_return(answer)
        subject.answer_link.should =~ /href=\"#{view.status_url(answer)}\"/
      end

      context "when AnswerNotification#user is the original author" do
        let(:notification) do
          AnswerNotification.new(user: user, answer: answer)
        end
        let(:status) { FactoryGirl.build_stubbed(:activity, user: user) }

        context "#action" do
          it "should generate the correct message" do
            subject.action.should =~ \
              /respondeu ao seu comentário em/
          end
        end

        context "#subject" do
          it "should generate the correct message" do
            subject.subject.should =~ \
              /#{answer.user.display_name} respondeu ao seu comentário em/
          end
        end
      end

      context "whem AnswerNotification#user is not the original author" do
        let(:notification) { AnswerNotification.new(user: user, answer: answer) }

        context "#action" do
          it "should generate the correct message" do
            msg = "também respondeu ao comentário " + \
              "original de #{status.user.display_name}"

            subject.action.should == msg
          end
        end

        context "#subject" do
          it "should generate the correct message" do
            msg = "#{answer.user.display_name} também respondeu ao comentário " + \
                  "original de #{status.user.display_name}"

            subject.subject.should == msg
          end
        end
      end

      context "#template" do
        it "should raise a runtime error when there is no template" do
          msg = \
            "No template defined. You need to pass :template to new or use #context"

          expect {
            AnswerPresenter.new.template
          }.to raise_error /#{msg}/
        end
      end

      context "#context" do
        it "should yield controll with AnswerPresenter" do
          expect { |b| subject.context(view, &b) }.to yield_with_args(subject)
        end

        it "should keep the original template" do
          subject.context("blah!")
          subject.template.should == view
        end

        it "should ensure original template" do
          begin
            subject.context("blah!") do
              raise "exception"
            end
          rescue Exception
          end

          subject.template.should == view
        end
      end
    end
  end
end
