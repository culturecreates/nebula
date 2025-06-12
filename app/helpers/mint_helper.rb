module MintHelper

  # 
  def classToReconcile(classToMint)
    if classToMint.class == RDF::URI
      classToMint = classToMint.value
    end

    if classToMint == "http://schema.org/Person" || classToMint == "http://schema.org/Organization"
      "dbo:Agent"
    else
      classToMint
    end
  end

end
