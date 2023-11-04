# frozen_string_literal: true

##
# User authentication
class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all, it will apply to every resource. Otherwise, pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects. For example, here the user can only update published articles.
    #   can :update, Article, :published => true
    #
    # The block argument takes as a parameter an instance of the object for which
    # permission is being checked. If the block returns true, the user is granted that
    # ability, otherwise the user is denied that ability. The block is only evaluated
    # for instances of objects, *not* for classes. If a class is passed to a `can?` or a
    # `cannot?` that's defined by a block, that check will *always* grant permission.
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities-with-Blocks

    # NOTE: the below ability definitions which reference StacksFile also implicitly
    # cover StacksImage and StacksMediaStream, and any other subclasses of StacksFile.

    downloadable_models = [StacksFile, StacksImage]
    access_models = downloadable_models + [StacksMediaStream]

    can :download, downloadable_models do |f|
      value, rule = f.rights.world_rights_for_file f.file_name

      value && (rule.nil? || rule != Dor::RightsAuth::NO_DOWNLOAD_RULE)
    end

    can [:access], access_models do |f|
      value, _rule = f.rights.world_rights_for_file f.file_name

      value
    end

    if user.stanford?
      can :download, downloadable_models do |f|
        value, rule = f.rights.stanford_only_rights_for_file f.file_name

        value && (rule.nil? || rule != Dor::RightsAuth::NO_DOWNLOAD_RULE)
      end

      can [:access], access_models do |f|
        value, _rule = f.rights.stanford_only_rights_for_file f.file_name

        value
      end
    end

    if user.locations.present?
      can :download, downloadable_models do |f|
        user.locations.any? do |location|
          value, rule = f.rights.location_rights_for_file(f.file_name, location)
          value && (rule.nil? || rule != Dor::RightsAuth::NO_DOWNLOAD_RULE)
        end
      end

      can [:access], access_models do |f|
        user.locations.any? do |location|
          value, _rule = f.rights.location_rights_for_file(f.file_name, location)
          value
        end
      end
    end

    if user.cdl_tokens.present?
      # TODO: Actually check if the CDL object is downloadable
      # can [:download, :read], models do |f|
      #   ...
      # end

      can [:access], access_models do |f|
        value, _rule = f.rights.cdl_rights_for_file(f.file_name)
        next unless value

        user.cdl_tokens.any? { |payload| payload['aud'] == f.id }
      end
    end

    cannot :download, RestrictedImage

    # These are called when checking to see if the image response should be served
    can [:download, :read], Projection do |projection|
      can?(:download, projection.image)
    end

    can [:download, :read], Projection do |projection|
      # Allow access to tile or thumbnail-sized requests for an accessible image
      (projection.tile? || projection.thumbnail?) && can?(:access, projection.image)
    end

    can :access, Projection do |projection|
      can?(:access, projection.image)
    end

    can :read, Projection do |projection|
      # Allow access to thumbnail-sized projections of a declared (or implicit) thumbnail for the object;
      # note that because this is implicit, we do not check rightsMetadata permissions.
      projection.thumbnail? && projection.object_thumbnail?
    end

    alias_action :stream, to: :access
    can :read_metadata, StacksImage
  end
end
