# frozen_string_literal: true

require_relative "../v3_1brc"

describe V3 do
  it "does something" do
    expect(V3::compute)
      .to(eq(Pathname(__dir__).join("expected-output.txt").read.chomp))
  end
end
