# frozen_string_literal: true

require_relative "../v1_1brc"

describe V1::OneBRC do
  it "does something" do
    expect(V1::OneBRC.compute)
      .to(eq(Pathname(__dir__).join("expected-output.txt").read.chomp))
  end
end
