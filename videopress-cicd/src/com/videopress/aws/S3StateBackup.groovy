package com.videopress.aws

/**
 * Helper backup tfstate file lên S3 archive bucket trước khi `terraform apply`.
 *
 * Bucket archive lưu state với versioning, KHÁC bucket gốc của backend Terraform,
 * để rollback có thể đối chiếu 2 nguồn (S3 versioning của state bucket + archive).
 */
class S3StateBackup implements Serializable {

  private static final long serialVersionUID = 1L

  def script

  S3StateBackup(def script) {
    this.script = script
  }

  /**
   * Backup state file từ bucket gốc → bucket archive với timestamp.
   *
   * @param bucket         S3 bucket chứa state hiện tại (ví dụ 'videopress-tfstate-prod').
   * @param key            Key trong bucket (ví dụ 'prod/terraform.tfstate').
   * @param archiveBucket  Bucket archive lưu lâu (ví dụ 'videopress-state-archive').
   * @return  Path archive đã tạo.
   */
  String backupBeforeApply(String bucket, String key, String archiveBucket) {
    assert bucket        : "S3StateBackup: 'bucket' rỗng"
    assert key           : "S3StateBackup: 'key' rỗng"
    assert archiveBucket : "S3StateBackup: 'archiveBucket' rỗng"

    def timestamp = new Date().format("yyyyMMdd-HHmmss")
    def buildId   = script.env.BUILD_ID ?: 'local'
    def archiveKey = "${key}.${timestamp}.b${buildId}.bak"

    script.sh """
      set -e
      aws s3 cp s3://${bucket}/${key} ./tfstate-current.bak
      aws s3 cp ./tfstate-current.bak s3://${archiveBucket}/${archiveKey} \\
        --metadata buildId=${buildId},sourceBucket=${bucket}
      rm -f ./tfstate-current.bak
      echo "State backup → s3://${archiveBucket}/${archiveKey}"
    """
    return "s3://${archiveBucket}/${archiveKey}"
  }
}
