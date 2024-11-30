# proxmox
I would like to generate Ubuntu template with Packer and Cloud-Init

source: github.com/christianlempa

cd ubuntu2404
packer validate -var-file="../credentailubuntu2404/plr.hcl" ./ubuntu.pkr.hcl
