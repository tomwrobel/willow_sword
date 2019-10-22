module WillowSword
  class Error
    attr_reader :errors, :message, :iri, :code

    def initialize(message, type=:default)
      type = :default unless errors.include?(type)
      err = errors.fetch(type, nil)
      @message = message
      @iri = err[:iri]
      @code = err[:code]
    end

    def errors
      {
        content: {
          iri: 'http://purl.org/net/sword/error/ErrorContent',
          code: 415
        },
        checksum_mismatch: {
          iri: 'http://purl.org/net/sword/error/ErrorChecksumMismatch',
          code: 412
        },
        bad_request: {
          iri: 'http://purl.org/net/sword/error/ErrorBadRequest',
          code: 400
        },
        target_owner_unknown: {
          iri: 'http://purl.org/net/sword/error/TargetOwnerUnknown',
          code: 403
        },
        not_found: {
          iri: 'http://purl.org/net/sword/error/ErrorNotFound',
          code: 404
        },
        mediation_not_allowed: {
          iri: 'http://purl.org/net/sword/error/MediationNotAllowed',
          code: 412
        },
        method_not_allowed: {
          iri: 'http://purl.org/net/sword/error/MethodNotAllowed',
          code: 405
        },
        max_upload_size_exceeded: {
          iri: 'http://purl.org/net/sword/error/MaxUploadSizeExceeded',
          code: 413
        },
        default: {
          iri: 'http://purl.org/net/sword/error/ErrorBadRequest',
          code: 400
        }
      }
    end
  end
end
