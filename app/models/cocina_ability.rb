# frozen_string_literal: true

##
# User authentication
class CocinaAbility
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
      f.rights.download == 'world'
    end

    can [:access], access_models do |f|
      f.rights.view == 'world'
    end

    if user.stanford?
      can :download, downloadable_models do |f|
        f.rights.download == 'stanford'
      end

      can [:access], access_models do |f|
        f.rights.view == 'stanford'
      end
    end

    if user.locations.present?
      can :download, downloadable_models do |f|
        next unless f.rights.download == 'location-based'

        user.locations.include?(f.rights.location)
      end

      can [:access], access_models do |f|
        user.locations.any? do |_location|
          next unless f.rights.view == 'location-based'

          user.locations.include?(f.rights.location)
        end
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
