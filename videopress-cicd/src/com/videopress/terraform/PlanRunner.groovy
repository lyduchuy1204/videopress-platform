package com.videopress.terraform

/**
 * Wrapper chạy `terraform plan -out=`. Trả về summary text từ plan.
 */
class PlanRunner implements Serializable {

  private static final long serialVersionUID = 1L

  def script

  PlanRunner(def script) {
    this.script = script
  }

  /**
   * Chạy `terraform plan` trong workdir, ghi binary plan ra `planFile`.
   *
   * @param workdir  Đường dẫn folder chứa main.tf (ví dụ 'envs/uat').
   * @param planFile Tên file plan output (ví dụ 'tfplan.bin').
   * @return         Tóm tắt plan dưới dạng String (output của `terraform show -no-color`).
   */
  String plan(String workdir, String planFile) {
    assert workdir  : "PlanRunner.plan: 'workdir' rỗng"
    assert planFile : "PlanRunner.plan: 'planFile' rỗng"

    script.dir(workdir) {
      script.sh "terraform plan -out=${planFile} -input=false -no-color"
    }
    def summary = script.sh(
      script: "terraform -chdir=${workdir} show -no-color ${planFile}",
      returnStdout: true
    )
    return summary.trim()
  }
}
