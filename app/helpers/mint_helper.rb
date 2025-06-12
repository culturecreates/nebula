module MintHelper

  def classToReconcile(classToMint)
    if classToMint.value == "http://schema.org/Person" || classToMint.value == "http://schema.org/Organization"
      "dbo:Agent"
    else
      classToMint
    end
  end

end
