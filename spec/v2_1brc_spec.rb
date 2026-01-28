# frozen_string_literal: true

require_relative "../v2_1brc"

describe V2::OneBRC do
  it "does something" do
    expect(V2::OneBRC.compute)
      .to(eq(Pathname(__dir__).join("expected-output.txt").read.chomp))
  end
end
