import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { KioskService } from '../../core/services/kiosk.service';
import { Project, Employee, TimeRecord } from '../../core/models';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { format } from 'date-fns';
import { ConfirmationModalComponent } from '../../shared/components/confirmation-modal/confirmation-modal.component';

enum KioskState {
  ENTER_CEDULA = 'ENTER_CEDULA',
  SHOW_ACTION = 'SHOW_ACTION',
  SELECT_PROJECT = 'SELECT_PROJECT',
  PROCESSING = 'PROCESSING',
  SUCCESS = 'SUCCESS',
  ERROR = 'ERROR'
}

interface EmployeeStatus {
  employee: Employee;
  hasActiveShift: boolean;
  activeRecord?: TimeRecord;
}

@Component({
  selector: 'app-checkin',
  standalone: true,
  imports: [CommonModule, FormsModule, ConfirmationModalComponent],
  templateUrl: './checkin.component.html',
  styleUrl: './checkin.component.scss'
})
export class CheckinComponent implements OnInit {
  currentState: KioskState = KioskState.ENTER_CEDULA;
  cedula: string = '';
  selectedProjectId: string = '';
  projects: Project[] = [];
  employeeStatus: EmployeeStatus | null = null;
  message: string = '';
  showCloseModal: boolean = false;

  KioskState = KioskState;

  constructor(
    private kioskService: KioskService,
    private router: Router
  ) { }

  async ngOnInit() {
    const token = this.kioskService.getIslandToken();
    if (!token) {
      this.router.navigate(['/kiosk/activate']);
      return;
    }
    await this.loadProjects();
  }

  async loadProjects() {
    const { data } = await this.kioskService.getActiveProjects();
    if (data) {
      this.projects = data;
    }
  }

  onCedulaInput(event: Event) {
    const input = event.target as HTMLInputElement;
    input.value = input.value.replace(/\D/g, '');
    this.cedula = input.value;
  }

  async checkEmployee() {
    if (!this.cedula.trim() || !/^\d+$/.test(this.cedula.trim())) {
      this.showError('Por favor ingrese una cédula válida');
      return;
    }

    this.currentState = KioskState.PROCESSING;

    const { employee, error: empError } = await this.kioskService.getEmployeeByCedula(this.cedula.trim());

    if (empError || !employee) {
      this.showError('Empleado no encontrado o inactivo');
      return;
    }

    const hasActiveShift = await this.kioskService.hasActiveShift(employee.id);

    let activeRecord: TimeRecord | undefined;
    if (hasActiveShift) {
      const { data } = await this.kioskService.getActiveTimeRecord(employee.id);
      if (data) {
        activeRecord = data;
      }
    }

    this.employeeStatus = {
      employee,
      hasActiveShift,
      activeRecord
    };

    this.currentState = KioskState.SHOW_ACTION;
  }

  goToProjectSelection() {
    this.currentState = KioskState.SELECT_PROJECT;
  }

  async performCheckIn() {
    if (!this.selectedProjectId) {
      this.showError('Por favor seleccione un proyecto');
      return;
    }

    this.currentState = KioskState.PROCESSING;

    const token = this.kioskService.getIslandToken()!;
    const result = await this.kioskService.checkIn({
      cedula: this.cedula.trim(),
      project_id: this.selectedProjectId,
      island_token: token
    });

    if (result.success) {
      this.showSuccess(`¡Bienvenido, ${this.employeeStatus!.employee.full_name}! Entrada registrada exitosamente.`);
    } else {
      this.showError(result.error || 'Error al registrar la entrada');
    }
  }

  async performCheckOut() {
    this.currentState = KioskState.PROCESSING;

    const token = this.kioskService.getIslandToken()!;
    const result = await this.kioskService.checkOut({
      cedula: this.cedula.trim(),
      island_token: token
    });

    if (result.success) {
      this.showSuccess(`¡Hasta luego, ${this.employeeStatus!.employee.full_name}! Salida registrada exitosamente.`);
    } else {
      this.showError(result.error || 'Error al registrar la salida');
    }
  }

  showSuccess(message: string) {
    this.currentState = KioskState.SUCCESS;
    this.message = message;
    setTimeout(() => this.resetFlow(), 5000);
  }

  showError(message: string) {
    this.currentState = KioskState.ERROR;
    this.message = message;
    setTimeout(() => {
      this.currentState = KioskState.ENTER_CEDULA;
      this.message = '';
    }, 5000);
  }

  resetFlow() {
    this.currentState = KioskState.ENTER_CEDULA;
    this.cedula = '';
    this.selectedProjectId = '';
    this.employeeStatus = null;
    this.message = '';
  }

  goBack() {
    if (this.currentState === KioskState.SHOW_ACTION) {
      this.currentState = KioskState.ENTER_CEDULA;
      this.employeeStatus = null;
    } else if (this.currentState === KioskState.SELECT_PROJECT) {
      this.currentState = KioskState.SHOW_ACTION;
      this.selectedProjectId = '';
    }
  }

  getCheckInTime(): string {
    if (this.employeeStatus?.activeRecord?.check_in) {
      return format(new Date(this.employeeStatus.activeRecord.check_in), 'HH:mm');
    }
    return '--:--';
  }

  getElapsedTime(): string {
    if (this.employeeStatus?.activeRecord?.check_in) {
      const start = new Date(this.employeeStatus.activeRecord.check_in);
      const now = new Date();
      const diff = now.getTime() - start.getTime();
      const hours = Math.floor(diff / (1000 * 60 * 60));
      const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
      return `${hours}h ${minutes}m`;
    }
    return '0h 0m';
  }

  getCurrentProject(): string {
    if (this.employeeStatus?.activeRecord?.project) {
      const project = this.employeeStatus.activeRecord.project as any;
      return `${project.code} - ${project.name}`;
    }
    return 'Sin proyecto activo';
  }

  deactivateIsland() {
    this.showCloseModal = true;
  }

  confirmCloseKiosk() {
    this.showCloseModal = false;
    this.kioskService.clearIslandToken();
    this.router.navigate(['/kiosk/activate']);
  }

  cancelCloseKiosk() {
    this.showCloseModal = false;
  }
}
