class Project < ApplicationRecord
  validates :name, presence: { message: "Did you forget to add a name?" }
end
