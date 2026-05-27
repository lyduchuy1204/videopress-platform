package com.videopress.terraform

/**
 * Wrapper chạy `terraform apply` từ plan file đã sinh sẵn.
 *
 * Bắt buộc dùng plan file (KHÔNG `apply -auto-approve` mà không có plan)
 * để tránh race condition state thay đổi giữa lúc plan và lúc apply.
 */
class ApplyRunner implements Serializable {

  private static final long serialVersionUID = 1L

  def script

  ApplyRunner(def script) {
    this.script = script
  }

  /**
   * Apply plan đã tạo trước đó.
   *
   * @param workdir   Đường dẫn folder env.
   * @param planFile  Plan binary do `PlanRunner` sinh ra.
   * @return  Output text của apply.
   */
  String apply(String workdir, String planFile) {
    assert workdir  : "ApplyRunner.apply: 'workdir' rỗng"
    assert planFile : "ApplyRunner.apply: 'planFile' rỗng"

    def output = script.sh(
      script: "terraform -chdir=${workdir} apply -input=false -no-color ${planFile}",
      returnStdout: true
    )
    return output
  }
}
