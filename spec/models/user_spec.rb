require 'rails_helper'

describe User do

  subject { create(:user) }

  it { should validate_uniqueness_of(:email) }
  it { should validate_uniqueness_of(:username) }
  it { should allow_value('test1', '1test').for(:username) }
  it { should_not allow_value('portus', 'foo', '1Test', 'another_test').for(:username) }

  it 'should block user creation when the private namespace is not available' do
    name = 'coolname'
    team = create(:team, owners: [ subject ])
    create(:namespace, team: team, name: name)
    user = build(:user, username: name)
    expect(user.save).to be false
    expect(user.errors.size).to eq(1)
    expect(user.errors.first).to match_array([:username, 'cannot be used as name for private namespace'])
  end

  describe '#create_personal_namespace!' do

    context 'no registry defined yet' do
      before :each do
        expect(Registry.count).to be(0)
      end

      it 'does nothing' do
        subject.create_personal_namespace!

        expect(Team.find_by(name: subject.username)).to be(nil)
        expect(Namespace.find_by(name: subject.username)).to be(nil)
      end

    end

    context 'registry defined' do
      before :each do
        create(:user, admin: true)
        create(:registry)
      end

      it 'creates a team and a namespace with the name of username' do
        subject.create_personal_namespace!
        team = Team.find_by!(name: subject.username)
        Namespace.find_by!(name: subject.username)
        TeamUser.find_by!(user: subject, team: team)
        expect(team.owners).to include(subject)
        expect(team).to be_hidden
      end
    end

  end
end
