---------------------------
Disclaimer
---------------------------
The software is provided "as is," without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and noninfringement. In no event shall the authors or copyright holders be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the software or the use or other dealings in the software.

This software is not intended for use in the diagnosis, treatment, cure, or prevention of any disease or medical condition. Users should not rely on this software as a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of a qualified healthcare provider with any questions you may have regarding a medical condition.


---------------------------
Prerequisites
---------------------------
Before using this software, please ensure that your system meets the following prerequisites:
Hardware:
- A computer with a minimum of 2 GHz dual-core processor.
- At least 4 GB of RAM.
- A minimum of 2 GB MB of available disk space.

Operating system:
- Linux Centos7 or higher

Software dependencies:
- Matlab 2018a or higher
- SPM 12 (make sure it is added to your Matlab path)
- Tools for NIfTI and ANALYZE image v1.27.0 (make sure it is added to your Matlab path)
- FSL 6.0 or higher with FSLeyes

---------------------------
Installation
---------------------------
1) git clone https://github.com//HybridFlow.git 
2) cd HybridFlow


---------------------------
User instructions
---------------------------
1) Set workingDir and dicomDir in pipeline.sh
2) Make sure pre-processed data, i.e. T1-map, motion-corrected DCE-MRI data, all images aligned to same reference space) are available in the workingDir directory
3) Run pipeline.sh

---------------------------
Acknowledgements
---------------------------
Please acknowledge this work using the citation below:

M. van den Kerkhof, J.J.A. de Jong, P.H.M. Voorter, A. Postma, A.A. Kroon, R.J. van Oostenbrugge, J.F.A. Jansen, W.H. Backes. Blood-brain barrier integrity decreases with higher blood pressure: a 7T DCE-MRI study
