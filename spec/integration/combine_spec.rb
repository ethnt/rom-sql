require 'spec_helper'

describe 'Eager loading' do
  include_context 'users and tasks'

  before do
    setup.relation(:users) do
      def by_name(name)
        where(name: name)
      end
    end

    setup.relation(:tasks) do
      def for_users(users)
        where(user_id: users.map { |tuple| tuple[:id] })
      end
    end

    setup.relation(:tags) do
      def for_tasks(tasks)
        inner_join(:task_tags, task_id: :id)
          .where(task_id: tasks.map { |tuple| tuple[:id] })
      end
    end
  end

  it 'issues 3 queries for 3 combined relations' do
    users = rom.relation(:users).by_name('Piotr')
    tasks = rom.relation(:tasks)
    tags = rom.relation(:tags)

    relation = users.combine(tasks.for_users.combine(tags.for_tasks))

    # TODO: figure out a way to assert correct number of issued queries
    expect(relation.call).to be_instance_of(ROM::Relation::Loaded)
  end
end
