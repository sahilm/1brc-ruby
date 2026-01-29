# frozen_string_literal: true

require_relative "../v4_1brc"

describe V4 do
  it "does something" do
    expect(V4::compute)
      .to(eq(Pathname(__dir__).join("expected-output.txt").read.chomp))
  end
end
