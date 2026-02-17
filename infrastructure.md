# Homelab Infrastructure Overview

This document provides a visual overview of the homelab network and server rack layout, defined using Mermaid for "documentation as code."

```mermaid
graph TD
    subgraph Internet Edge
        I(Internet)
        UCI[Unifi UCI Modem]
    end

    subgraph Unifi Rack 1 (Network Core)
        direction LR
        UDMSE[UDM-SE
(Router, Firewall)]
        PatchPanel[24-Port Keystone Patch Panel]
        USWPM24(USW Pro Max 24
(Core Switch))
    end

    subgraph Unifi Rack 2 (Power & UPS)
        direction LR
        PDU[Unifi UPS PDU Pro]
        UPS[Unifi UPS 2U]
        RPS[Unifi USP RPS]
    end

    subgraph Main Server Rack (Servers & Storage)
        direction TD
        k8s0[k8s-0
(GEEKOM Mini IT13)]
        k8s1[k8s-1
(GEEKOM Mini IT13)]
        k8s2[k8s-2
(GEEKOM Mini IT13)]
        QNAP[QNAP TS-462 NAS]
    end

    subgraph Distributed Switches & Access Points
        USWUltra8[USW Ultra 8 Port
(Dist. Switch)]
        USWFlex[USW Flex
(Outdoor Switch)]
        U6LR(U6-LR AP)
        U7Pro(U7 Pro AP)
        U7Outdoor(U7 Outdoor AP)
    end

    %% --- Internet Edge Connections ---
    I -- "Fiber/Coax" --> UCI
    UCI -- "Ethernet" --> UDMSE

    %% --- Unifi Rack 1 Internal Connections ---
    UDMSE -- "10GbE SFP+ / VLAN 1" --> USWPM24
    PatchPanel -- "Eth" --> USWPM24

    %% --- Inter-Rack Connections ---
    USWPM24 -- "VLAN 30 (Homelab)" --> k8s0
    USWPM24 -- "VLAN 30 (Homelab)" --> k8s1
    USWPM24 -- "VLAN 30 (Homelab)" --> k8s2
    USWPM24 -- "10GbE SFP+ / VLAN 30" --> QNAP

    %% --- Power Connections (Conceptual) ---
    PDU --- UPS
    UPS --- RPS

    %% --- Distributed Network ---
    USWPM24 -- "Port 24" --> USWUltra8
    USWUltra8 -- "Downlink" --> USWFlex
    USWUltra8 --> U7Pro[U7 Pro AP]
    USWUltra8 --> U6LR[U6-LR AP (Barn)]
    USWFlex --> U7Outdoor[U7 Outdoor AP]

    %% --- Node / NAS Placement Labels (Not part of Mermaid graph, but for clarity) ---
    k8s0 -.- placement_k8s_label[On Shelf Above Main Server Rack]
    k8s1 -.- placement_k8s_label
    k8s2 -.- placement_k8s_label
    QNAP -.- placement_qnap_label[On Shelf Above Main Server Rack]
```